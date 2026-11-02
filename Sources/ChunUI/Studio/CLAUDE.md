# Studio/
> L2 | 父级: ../../../CLAUDE.md

工作室层：赵纯想工作室四个 App（胃之书、阿奇、哒啦啦、口袋粉丝）一字不差的那部分能力，只在这里写一次。
宿主只做四件事：启动时 configure（工作室身份、语言与外观的旧存储键）、注入品牌皮肤（Color.cc 调色板 + CCFormStyle 字号；卡面四端唯一，不注入）、根视图挂 ccLanguageRoot()、设置页用下列件拼、一级页头左上摆 CCRootBrand。
页面外壳（导航、页头行、资料头）与业务行（账号组、通用组里的业务项）留在宿主；图标一律 Pika。

成员清单
CCLanguage.swift: 运行时语言唯一实现。可选语言缺省取 App 包的 lproj；所选存宿主给的键并写 AppleLanguages；取词包 Bundle.appLanguage 与语言码 CCLanguage.currentCode 任意线程可读；切换即时生效（根视图按 epoch 重挂），不需要重启；排版 Locale 跟随系统时取系统 Locale（保留地区格式）。
CCAppearance.swift: 外观三选一（跟随系统 · 浅色 · 深色），窗口级 overrideUserInterfaceStyle，UIKit 壳与 sheet 一并生效。
CCStudio.swift: 工作室身份（App Store id、分享文案（分享时求值，随语言变）、作品目录地址、外链出口 openURL）、评分（直达写评价页）、分享面板；CCAppStore 应用内商店页；CCStudioText 工作室通用文案（含头像钮的无障碍名 settings）。
CCStudioWorks.swift: 作品目录客户端。…/works?lang=<生效语言> 只认 data.items（各 App 信封的 code 不同形）；整份缓存，失败保留旧值，空表即隐藏。
CCSettingsKit.swift: 设置页骨架。CCSettingsItem（名字 · 图标 · 副标题 · 现值 · 红点）/ CCSettingsGroup / CCSettingsStack；CCStudioGroups 出语言行、外观行、信息组四行（意见反馈可带红点）、更多组（开发者 · 小红书 · X · 本应用一行）、退出登录；CCWorksGroup；CCLanguageGroup / CCAppearanceGroup 单选卡（轻触感、可选 onPick）；CCSettingsSignature 两行落款。
CCRootBrand.swift: 一级页头左上的品牌位（四端页头范式唯一实现）：圆头像钮 40（缺省进设置；阿奇呼出侧边栏，宿主给 actionLabel；可挂未读点）· 间距 12 · 英文小写字标高 26（宿主主包 Wordmark 模板矢量，deploy/ios/wordmark 生成）。字标画布纵向中心即 x 高中线，居中即对准头像圆心；头像内容与字标颜色归宿主。
Studio.xcstrings: 工作室通用文案，二十种语言（四个 App 语言的并集），表名 Studio；CCStudioText 按 CCLanguage 的生效语言从 Bundle.module 的 lproj 取。

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
