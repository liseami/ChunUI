/**
 * [INPUT]: 依赖 UIKit UIImagePickerController（sourceType .camera）、CCPresentationAnchor 顶层呈现锚点、Presentation 的 CCNav.present（呈现出口）、AppHelper 触感
 * [OUTPUT]: 对外提供 AppHelper.presentCamera(onCapture:)——命令式拉起系统相机拍一张，回调主线程 UIImage；无相机（模拟器）静默返回 false
 * [POS]: Components 的相机拍摄唯一命令式出口，与 CCPHPicker（相册）并列；coordinator 经关联对象强持，防 present 后释放；禁止业务页自建 UIImagePickerController
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import ObjectiveC
import UIKit

extension AppHelper {
    /// 命令式拉起系统相机拍照；相机不可用（模拟器 / 无权限设备）返回 false，不弹任何东西
    @discardableResult
    public func presentCamera(onCapture: @escaping (UIImage) -> Void) -> Bool {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return false }
        Task { @MainActor in
            AppHelper.shared.mada(.soft)
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = false
            let coordinator = CCCameraPickerCoordinator(onCapture: onCapture)
            picker.delegate = coordinator
            objc_setAssociatedObject(
                picker,
                &CCCameraPickerCoordinator.assocKey,
                coordinator,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            guard let presenter = CCPresentationAnchor.topmost() else { return }
            CCNav.present(picker, from: presenter, animated: true)
        }
        return true
    }
}

private final class CCCameraPickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    static var assocKey: UInt8 = 0

    private let onCapture: (UIImage) -> Void

    init(onCapture: @escaping (UIImage) -> Void) {
        self.onCapture = onCapture
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        picker.dismiss(animated: true)
        guard let image else { return }
        Task { @MainActor in onCapture(image) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
