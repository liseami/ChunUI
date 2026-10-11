# Core/
> L2 | 父级: ../../../CLAUDE.md

包门面层：配置入口、导入基座与命名空间，宿主与包的唯一契约面。

成员清单
ChunUI.swift: 包门面——configure(colors:strings:) 唯一初始化入口 + defaultAvatarURL/hapticsEnabled/sheetPageNameHook 接线座
CCStrings.swift: 组件内建文案可覆写表（默认英文），current 由 configure 写入，组件禁直连 String(localized:)
CCExports.swift: @_exported 系统框架基座（SwiftUI/UIKit/Combine/Foundation/QuartzCore），第三方禁入
CCDesign.swift: CCDesigin 公开命名空间 + 组件 Preview
Blur.swift: CCLayerFilter 是 CAFilter 的唯一入口；VariableBlurView 渐进模糊原子（variableBlur，上下/左右方向）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
