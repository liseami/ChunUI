/**
 * [INPUT]: 依赖 PhotosUI PHPickerViewController、UniformTypeIdentifiers、PickedMedia/PickedVideoFile（R2Uploader）、CCPresentationAnchor、CCNav.present（呈现出口）、UploadProgressCenter
 * [OUTPUT]: 对外提供 MediaPickLimit.maxPerSession（图+视频合计 6）与 MainViewModel.presentPHPicker——命令式系统相册多选，回调 [PickedMedia]
 * [POS]: DesignSystem/Compents 的相册选取唯一命令式出口；禁止业务页 .photosPicker / PhotosPicker 视图挂载；选完立刻上传的路径 showsUploadToast=true，点确认即出进度胶囊，不等 iCloud 解码
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import ObjectiveC
import PhotosUI

/// 已选媒体：图片直出 UIImage；视频为已落地本地临时文件
public enum PickedMedia: Equatable {
    case image(UIImage)
    case video(URL)
}
import UIKit
import UniformTypeIdentifiers

/// 一次 PHPicker 会话的媒体上限：图 + 视频合计，不是各算各的
public enum MediaPickLimit {
    public static let maxPerSession = 6
}

extension AppHelper {
    /// 命令式弹出系统 PHPicker（图/视频），结果解码为 PickedMedia 后回主线程；showsUploadToast 为 true 时点确认即起进度胶囊
    public func presentPHPicker(
        selectionLimit: Int,
        filter: PHPickerFilter = .any(of: [.images, .videos]),
        showsUploadToast: Bool = false,
        onPick: @escaping ([PickedMedia]) -> Void
    ) {
        Task { @MainActor in
            AppHelper.shared.mada(.soft)
            var config = PHPickerConfiguration(photoLibrary: .shared())
            let requested = max(0, selectionLimit)
            config.selectionLimit = requested == 0 ? 0 : min(requested, MediaPickLimit.maxPerSession)
            config.filter = filter
            let picker = PHPickerViewController(configuration: config)
            let coordinator = CCPHPickerCoordinator(
                showsUploadToast: showsUploadToast,
                onPick: onPick
            )
            picker.delegate = coordinator
            // 强持 coordinator，防 present 后释放
            objc_setAssociatedObject(
                picker,
                &CCPHPickerCoordinator.assocKey,
                coordinator,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            guard let presenter = CCPresentationAnchor.topmost() else { return }
            CCNav.present(picker, from: presenter, animated: true)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Coordinator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private final class CCPHPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
    static var assocKey: UInt8 = 0

    private let showsUploadToast: Bool
    private let onPick: ([PickedMedia]) -> Void

    public init(showsUploadToast: Bool, onPick: @escaping ([PickedMedia]) -> Void) {
        self.showsUploadToast = showsUploadToast
        self.onPick = onPick
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // 点确认立刻出胶囊：解码/iCloud 下载不能挡第一帧
        if showsUploadToast, !results.isEmpty {
            announceUploadToast(count: results.count)
        }
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        Task {
            let media = await Self.loadAll(results)
            if showsUploadToast, media.isEmpty {
                await MainActor.run { UploadProgressCenter.shared.endSession(after: 0.2) }
                return
            }
            await MainActor.run { onPick(media) }
        }
    }

    private func announceUploadToast(count: Int) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                UploadProgressCenter.shared.begin(count: count)
            }
        } else {
            Task { @MainActor in
                UploadProgressCenter.shared.begin(count: count)
            }
        }
    }

    /// 并行解码，保序；视频 copy 到临时目录、图片走 UIImage
    private static func loadAll(_ results: [PHPickerResult]) async -> [PickedMedia] {
        await withTaskGroup(of: (Int, PickedMedia?).self) { group in
            for (index, result) in results.enumerated() {
                group.addTask {
                    (index, await loadMedia(from: result.itemProvider))
                }
            }
            var slots: [PickedMedia?] = Array(repeating: nil, count: results.count)
            for await (index, item) in group {
                slots[index] = item
            }
            return slots.compactMap { $0 }
        }
    }

    private static func loadMedia(from provider: NSItemProvider) async -> PickedMedia? {
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            if let url = await loadMovieURL(from: provider) {
                return .video(url)
            }
        }
        if provider.canLoadObject(ofClass: UIImage.self) {
            if let image = await loadUIImage(from: provider) {
                return .image(image)
            }
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let data = await loadData(from: provider, type: UTType.image.identifier),
               let image = UIImage(data: data) {
                return .image(image)
            }
        }
        return nil
    }

    private static func loadUIImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { cont in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                cont.resume(returning: object as? UIImage)
            }
        }
    }

    private static func loadData(from provider: NSItemProvider, type: String) async -> Data? {
        await withCheckedContinuation { cont in
            provider.loadDataRepresentation(forTypeIdentifier: type) { data, _ in
                cont.resume(returning: data)
            }
        }
    }

    private static func loadMovieURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { cont in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                guard let url else {
                    cont.resume(returning: nil)
                    return
                }
                let ext = url.pathExtension.isEmpty ? "mov" : url.pathExtension
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).\(ext)")
                try? FileManager.default.removeItem(at: dest)
                do {
                    try FileManager.default.copyItem(at: url, to: dest)
                    cont.resume(returning: dest)
                } catch {
                    cont.resume(returning: nil)
                }
            }
        }
    }
}
