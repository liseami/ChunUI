# Core/
> L2 | 父级: ../../../CLAUDE.md

包门面层：配置入口、导入基座与命名空间，宿主与包的唯一契约面。

成员清单
ChunUI.swift: 包门面——configure(colors:strings:) 唯一初始化入口 + defaultAvatarURL/hapticsEnabled/sheetPageNameHook 接线座
CCStrings.swift: 组件内建文案可覆写表（默认英文），current 由 configure 写入，组件禁直连 String(localized:)
CCLog.swift: 包内统一日志出口（internal、nonisolated），薄封装 os.Logger，subsystem ChunUI；日志文案一律英文
CCComponentText.swift: 组件自带界面字的取词口（internal），经 CCStudioText.t 取 Components 表，语言跟 CCLanguage
Components.xcstrings: 组件自带界面字（日历表头、月份格式、演示面板），表名 Components，源语 en，语义 key，二十语同 Studio.xcstrings
CCDesign.swift: CCDesigin 公开命名空间 + 组件 Preview（Preview 段只在 DEBUG 编译）
Blur.swift: CCLayerFilter 是 CAFilter 的唯一入口；VariableBlurView 渐进模糊原子（variableBlur，上下/左右方向）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
