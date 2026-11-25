/**
 * [INPUT]: 依赖 PhotosUI 的 PHPickerViewController、Photos 的 PHAsset 取拍摄日期、Core/CCLog 记载入失败
 * [OUTPUT]: 对外提供 PhotoSelector / PhotoSelectorRepresentable（多选）、SinglePhotoSelector / SinglePhotoSelectorRepresentable（单选）、CCUIImage
 * [POS]: Components 的系统相册选择器；单选记住上次选图的拍摄日期（CCPhotoSelectMemory）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import PhotosUI
import SwiftUI
public struct PhotoSelector: View {
    var maxSelection: Int
    var completionHandler: (([UIImage]) -> Void)?
    public init(maxSelection: Int, completionHandler: (([UIImage]) -> Void)?) {
        self.maxSelection = maxSelection
        self.completionHandler = completionHandler
    }

    public var body: some View {
        PhotoSelectorRepresentable(maxSelection: maxSelection, completionHandler: completionHandler)
            .tint(Color.cc.foreground)
            .ignoresSafeArea()
    }
}

public struct PhotoSelectorRepresentable: UIViewControllerRepresentable {
    var maxSelection: Int
    var completionHandler: (([UIImage]) -> Void)?

    public init(maxSelection: Int, completionHandler: (([UIImage]) -> Void)?) {
        self.maxSelection = maxSelection
        self.completionHandler = completionHandler
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = maxSelection // 0 表示不限制选择数量
        config.filter = .images // 只允许选择照片
        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        var parent: PhotoSelectorRepresentable

        public init(_ parent: PhotoSelectorRepresentable) {
            self.parent = parent
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if results.isEmpty {
                picker.dismiss(animated: true)
                return
            }
            // 创建一个空的UIImage数组来存储图片
            var images = [UIImage]()

            // 创建一个 dispatchGroup 来处理异步加载图片
            let dispatchGroup = DispatchGroup()

            // 在视图顶层添加一个全屏的 view
            let loadingView = UIView(frame: UIScreen.cc_active.bounds)
            loadingView.backgroundColor = UIColor(Color.cc.foreground.opacity(0.1))

            // 创建一个 UIActivityIndicatorView，并将其加入到 loadingView 中心位置
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = .white
            spinner.center = loadingView.center

            loadingView.addSubview(spinner)
            spinner.startAnimating()

//            // 添加到顶层 window 上
//            Apphelper.shared.getWindow()?.addSubview(loadingView)

            // 遍历选中的结果
            for result in results {
                dispatchGroup.enter() // 进入 dispatchGroup

                // 异步加载选中的图片
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        CCLog.error("Error loading image: \(error.localizedDescription)", category: "PhotoSelector")
                    } else if let image = image as? UIImage {
                        images.append(image) // 加载成功，将图片加入数组
                    }
                    dispatchGroup.leave() // 离开 dispatchGroup
                }
            }

            // 当所有图片都加载完成后，执行以下代码
            dispatchGroup.notify(queue: .main) {
                // 隐藏指示器
                loadingView.removeFromSuperview()

                // 调用父视图的 completionHandler 方法，并传入已选图片数组
                self.parent.completionHandler?(images)

                // 隐藏图片选择器
                picker.dismiss(animated: true)
            }
        }
    }
}

public struct SinglePhotoSelector: View {
    var allowsEditing: Bool
    var completionHandler: (UIImage) -> Void
    public init(allowsEditing: Bool = true, completionHandler: @escaping ((UIImage) -> Void)) {
        self.completionHandler = completionHandler
        self.allowsEditing = allowsEditing
    }

    public var body: some View {
        SinglePhotoSelectorRepresentable(allowsEditing: allowsEditing, completionHandler: completionHandler)
            .tint(Color.cc.foreground)
            .ignoresSafeArea()
    }
}

public struct CCUIImage {
    var uiimage: UIImage
    var createDate: Date?
}

public struct SinglePhotoSelectorRepresentable: UIViewControllerRepresentable {
    var completionHandler: (UIImage) -> Void
    var allowsEditing: Bool
    public init(allowsEditing: Bool = true, completionHandler: @escaping ((UIImage) -> Void)) {
        self.completionHandler = completionHandler
        self.allowsEditing = allowsEditing
        DispatchQueue.main.async {
            CCPhotoSelectMemory.lastCreatedTime = nil
        }
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        // 使用PHPickerViewController而不是UIImagePickerController
        // 因为PHPickerViewController能更好地保留照片元数据
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator

        return picker
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: SinglePhotoSelectorRepresentable

        public init(_ parent: SinglePhotoSelectorRepresentable) {
            self.parent = parent
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let result = results.first else { return }

            // 获取图片信息
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error = error {
                    CCLog.error("Photo load failed: \(error.localizedDescription)", category: "PhotoSelector")
                    return
                }

                guard let self = self, let image = image as? UIImage else { return }

                // 尝试获取PHAsset以保留原始创建日期
                let assetIdentifier = result.assetIdentifier
                if let assetIdentifier = assetIdentifier {
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                    if let asset = fetchResult.firstObject {
                        // 打印日期进行调试
                        if let createDate = asset.creationDate {
                            DispatchQueue.main.async(execute: {
                                CCPhotoSelectMemory.lastCreatedTime = createDate
                            })
                        }
                        CCLog.debug("Photo creation date: \(asset.creationDate?.description ?? "unknown")", category: "PhotoSelector")
                    }
                }

                // 返回图片
                DispatchQueue.main.async {
                    self.parent.completionHandler(image)
                }
            }
        }
    }
}
