# Theme/
> L2 | 父级: ../../../CLAUDE.md

设计令牌层：调色板注入命门与字号/间距/动画铁律，全组件质感的根。

成员清单
CCColors.swift: 语义调色板 struct + CCColors.current 活体注入点 + Color.cc 访问器（nonisolated 纯值宇宙，shader 闭包可直取）
CCTypography.swift: Font.cc 三梯度字号铁律（sm 13/base 17/lg 24 + tabbar 例外），历史令牌折叠映射
CCTokens.swift: CGFloat.cc 间距/圆角/发丝线宽令牌
CCMotion.swift: 全局动画令牌（reveal 零过冲 timingCurve + wave 微过冲错峰 + ccPageRise 页切换）
CCModifiers.swift: 系统效果兼容边界（iOS 26 Liquid Glass / 18.6–25 微拟物同形降级：ccGlassEffect/softGlassStyle；isEnabled 关时换成 Glass.identity，开着且 interactive 为假时是不形变的 regular，materialize 为真才挂退场过渡；CCGlassEffectContainer(spacing:) 让靠近的玻璃融合；SoftGlassShape 含 .custom(AnyShape) 任意轮廓。含 UITextView 的那一块必须停在同一 parametricFamily，跨族会重建子树、键盘二次弹出）+ appleCard/ccGroupCard/shimmer
CCSheetChrome.swift: 沉底 Alert 浮空外形（floatingShape 上下角同心）
ViewFunc.swift: ccText 文字样式速写 + equatable(by:) 局部等价渲染原语 + 键盘/延时呈现修饰符
Color+Mix.swift: 颜色混合（微拟物高光/阴影计算）
Color+Hash.swift: 哈希稳定生成颜色
CCColorAccessor+YUI.swift: YUI 遗留语义色映射（兼容层，勿新增消费）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
