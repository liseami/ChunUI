//
//  CameraViewModel.swift
//  YUI
//
//  相机会话管理 + 镜头切换 + 拍照逻辑
//  核心原则：所见即所得 (WYSIWYG)
//

import AVFoundation
import CoreImage
import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Camera ViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public final class CCCameraViewModel: NSObject, ObservableObject {
    // ━━━ 公开状态 ━━━
    @Published var capturedImage: UIImage?
    @Published var permissionDenied = false
    @Published var currentFilter: CameraFilter = .none
    @Published var currentZoomIndex = 0

    let session = AVCaptureSession()

    // ━━━ 私有属性 ━━━
    private let output = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?
    private var isConfigured = false
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var availableCameras: [(device: AVCaptureDevice, label: String, zoomFactor: CGFloat)] = []

    // 预览框比例 (3:4 竖向)
    private let previewAspectRatio: CGFloat = 3.0 / 4.0

    // ━━━ 计算属性 ━━━
    var availableCameraCount: Int { max(availableCameras.count, 1) }

    var currentZoomLabel: String {
        guard currentZoomIndex < availableCameras.count else { return "1x" }
        return availableCameras[currentZoomIndex].label
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 生命周期
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func startSession() { checkPermissionAndConfigure() }

    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 镜头切换 (点击循环)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func cycleZoomLevel() {
        guard !availableCameras.isEmpty else { return }
        let nextIndex = (currentZoomIndex + 1) % availableCameras.count
        setZoomLevel(index: nextIndex)
    }

    private func setZoomLevel(index: Int) {
        guard index >= 0 && index < availableCameras.count else { return }
        let camera = availableCameras[index]

        if camera.device != currentDevice {
            switchToCamera(camera.device)
        }
        applyZoom(factor: camera.zoomFactor)

        DispatchQueue.main.async { self.currentZoomIndex = index }
    }

    private func switchToCamera(_ device: AVCaptureDevice) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()

            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }

            if let newInput = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
                self.currentDevice = device
            }

            self.session.commitConfiguration()

            // 切换镜头后自动对焦
            self.autoFocus()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 对焦
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// 自动对焦 (中心点)
    func autoFocus() {
        focus(at: CGPoint(x: 0.5, y: 0.5))
    }

    /// 手动对焦 (归一化坐标 0~1)
    func focus(at point: CGPoint) {
        guard let device = currentDevice else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            guard device.isFocusPointOfInterestSupported,
                  device.isExposurePointOfInterestSupported else { return }

            do {
                try device.lockForConfiguration()

                // 对焦
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus

                // 曝光
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose

                device.unlockForConfiguration()
            } catch {
                // 静默失败
            }
        }
    }

    private func applyZoom(factor: CGFloat) {
        guard let device = currentDevice else { return }
        let clamped = max(device.minAvailableVideoZoomFactor,
                         min(factor, min(device.maxAvailableVideoZoomFactor, 10.0)))

        try? device.lockForConfiguration()
        device.videoZoomFactor = clamped
        device.unlockForConfiguration()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 滤镜切换 (点击循环)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func cycleFilter() {
        let all = CameraFilter.allCases
        let idx = all.firstIndex(of: currentFilter) ?? 0
        currentFilter = all[(idx + 1) % all.count]
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 拍照
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func capturePhoto() {
        guard session.isRunning else { return }
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 权限 & 配置
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func checkPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

    private func configureSession() {
        guard !isConfigured else {
            if !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            let cameras = self.detectAvailableCameras()
            let defaultIndex = cameras.firstIndex { $0.label == "1x" } ?? 0

            guard !cameras.isEmpty,
                  let input = try? AVCaptureDeviceInput(device: cameras[defaultIndex].device),
                  self.session.canAddInput(input),
                  self.session.canAddOutput(self.output) else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.output)
            self.currentInput = input
            self.currentDevice = cameras[defaultIndex].device

            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.isConfigured = true
                self.availableCameras = cameras
                self.currentZoomIndex = defaultIndex
            }
        }
    }

    private func detectAvailableCameras() -> [(device: AVCaptureDevice, label: String, zoomFactor: CGFloat)] {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )

        var result: [(AVCaptureDevice, String, CGFloat)] = []
        let devices = discovery.devices

        if let ultraWide = devices.first(where: { $0.deviceType == .builtInUltraWideCamera }) {
            result.append((ultraWide, "0.5x", 1.0))
        }
        if let wideAngle = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            result.append((wideAngle, "1x", 1.0))
            result.append((wideAngle, "2x", 2.0))
        }
        if let telephoto = devices.first(where: { $0.deviceType == .builtInTelephotoCamera }) {
            result.append((telephoto, "3x", 1.0))
        }

        return result
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 拍照回调 + WYSIWYG 裁剪
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension CCCameraViewModel: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        // 立即停止相机会话，释放资源
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }

        // 后台处理图片，避免卡顿
        let filter = currentFilter
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let processed = self.processImageWYSIWYG(image, filter: filter)
            DispatchQueue.main.async {
                self.capturedImage = processed
            }
        }
    }

    /// 所见即所得裁剪：模拟 AVCaptureVideoPreviewLayer 的 resizeAspectFill 行为
    private func processImageWYSIWYG(_ image: UIImage, filter: CameraFilter) -> UIImage {
        // 1. 使用 CIImage(image:) 保留方向信息
        guard var ciImage = CIImage(image: image) else { return image }

        // 2. 应用方向校正 - 确保图像是"正立"的
        ciImage = ciImage.oriented(forExifOrientation: Int32(image.imageOrientation.exifOrientation))

        // 3. 应用滤镜
        if filter != .none {
            ciImage = filter.apply(to: ciImage, context: ciContext)
        }

        // 4. 计算 resizeAspectFill 裁剪区域 (与预览层完全一致)
        let imageWidth = ciImage.extent.width
        let imageHeight = ciImage.extent.height
        let imageAspect = imageWidth / imageHeight

        let cropRect: CGRect

        if imageAspect > previewAspectRatio {
            // 图片比预览框更"宽" → 裁剪左右两边
            let targetWidth = imageHeight * previewAspectRatio
            let xOffset = (imageWidth - targetWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: targetWidth, height: imageHeight)
        } else {
            // 图片比预览框更"高" → 裁剪上下两边
            let targetHeight = imageWidth / previewAspectRatio
            let yOffset = (imageHeight - targetHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageWidth, height: targetHeight)
        }

        let croppedImage = ciImage.cropped(to: cropRect)

        // 5. 渲染最终图像
        guard let cgImage = ciContext.createCGImage(croppedImage, from: croppedImage.extent) else {
            return image
        }

        // 6. 返回正确方向的 UIImage (orientation = .up，因为已经校正过了)
        return UIImage(cgImage: cgImage)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - UIImageOrientation → EXIF Orientation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension UIImage.Orientation {
    /// 将 UIImage.Orientation 转换为 EXIF orientation 值
    var exifOrientation: Int {
        switch self {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}
