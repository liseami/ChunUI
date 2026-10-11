
/**
 * [INPUT]: 依赖 CoreImage.CIFilterBuiltins 与 QuartzCore 的 CAFilter variableBlur 运行时能力
 * [OUTPUT]: 对外提供 CCLayerFilter（CAFilter 唯一入口）、VariableBlurDirection、VariableBlurView、VariableBlurUIView 渐进背景模糊组件
 * [POS]: DesignSystem 的通用变量模糊特效，被 MainView、ProfileEditView、VipBuyView 与 FloatingChatOverlay 复用
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import CoreImage.CIFilterBuiltins
import QuartzCore


/// CAFilter 是 QuartzCore 的私有类，只经运行时取。全包只此一处造它
public enum CCLayerFilter {
    public static func make(_ type: String) -> NSObject? {
        guard let cls = NSClassFromString("CAFilter") as? NSObject.Type,
              let filter = cls.perform(NSSelectorFromString("filterWithType:"), with: type)?.takeUnretainedValue() as? NSObject else {
            return nil
        }
        return filter
    }
}

public enum VariableBlurDirection {
    case blurredTopClearBottom
    case blurredBottomClearTop
    case blurredTrailingClearLeading
    case blurredLeadingClearTrailing
}


public struct VariableBlurView: UIViewRepresentable {
    
    public var maxBlurRadius: CGFloat = 20
    
    public var direction: VariableBlurDirection = .blurredTopClearBottom
    
    /// By default, variable blur starts from 0 blur radius and linearly increases to `maxBlurRadius`. Setting `startOffset` to a small negative coefficient (e.g. -0.1) will start blur from larger radius value which might look better in some cases.
    public var startOffset: CGFloat = 0
    
    public init(maxBlurRadius: CGFloat = 20, direction: VariableBlurDirection = .blurredTopClearBottom, startOffset: CGFloat = 0) {
        self.maxBlurRadius = maxBlurRadius
        self.direction = direction
        self.startOffset = startOffset
    }
    
    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius, direction: direction, startOffset: startOffset)
    }

    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
    }
}


/// credit https://github.com/jtrivedi/VariableBlurView
open class VariableBlurUIView: UIVisualEffectView {

    public init(maxBlurRadius: CGFloat = 20, direction: VariableBlurDirection = .blurredTopClearBottom, startOffset: CGFloat = 0) {
        super.init(effect: UIBlurEffect(style: .regular))

        guard let variableBlur = CCLayerFilter.make("variableBlur") else { return }

        // The blur radius at each pixel depends on the alpha value of the corresponding pixel in the gradient mask.
        // An alpha of 1 results in the max blur radius, while an alpha of 0 is completely unblurred.
        let gradientImage = makeGradientImage(startOffset: startOffset, direction: direction)

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImage, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // We use a `UIVisualEffectView` here purely to get access to its `CABackdropLayer`,
        // which is able to apply various, real-time CAFilters onto the views underneath.
        let backdropLayer = subviews.first?.layer

        // Replace the standard filters (i.e. `gaussianBlur`, `colorSaturate`, etc.) with only the variableBlur.
        backdropLayer?.filters = [variableBlur]
        
        // Get rid of the visual effect view's dimming/tint view, so we don't see a hard line.
        for subview in subviews.dropFirst() {
            subview.alpha = 0
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToWindow() {
        // fixes visible pixelization at unblurred edge (https://github.com/nikstar/VariableBlur/issues/1)
        guard let window, let backdropLayer = subviews.first?.layer else { return }
        backdropLayer.setValue(window.screen.scale, forKey: "scale")
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // `super.traitCollectionDidChange(previousTraitCollection)` crashes the app
    }
    
    private func makeGradientImage(width: CGFloat = 100, height: CGFloat = 100, startOffset: CGFloat, direction: VariableBlurDirection) -> CGImage { // much lower resolution might be acceptable
        let ciGradientFilter =  CIFilter.linearGradient()
//        let ciGradientFilter =  CIFilter.smoothLinearGradient()
        ciGradientFilter.color0 = CIColor.black
        ciGradientFilter.color1 = CIColor.clear
        ciGradientFilter.point0 = CGPoint(x: 0, y: height)
        ciGradientFilter.point1 = CGPoint(x: 0, y: startOffset * height) // small negative value looks better with vertical lines
        if case .blurredBottomClearTop = direction {
            ciGradientFilter.point0.y = 0
            ciGradientFilter.point1.y = height - ciGradientFilter.point1.y
        }
        if case .blurredTrailingClearLeading = direction {
            ciGradientFilter.point0 = CGPoint(x: width, y: 0)
            ciGradientFilter.point1 = CGPoint(x: startOffset * width, y: 0)
        }
        if case .blurredLeadingClearTrailing = direction {
            ciGradientFilter.point0 = CGPoint(x: 0, y: 0)
            ciGradientFilter.point1 = CGPoint(x: width - startOffset * width, y: 0)
        }
        return CIContext().createCGImage(ciGradientFilter.outputImage!, from: CGRect(x: 0, y: 0, width: width, height: height))!
    }
}
