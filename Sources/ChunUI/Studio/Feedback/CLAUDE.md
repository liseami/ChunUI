# Studio/Feedback/
> L2 | 父级: ../CLAUDE.md

意见箱唯一实现，胃之书定稿，四个 App 逐像素同构：顶部「提出 · 解决 · 邀请」分段，「解决」字后挂未读角标。
意见箱只认 CCFeedbackService 协议（DIP），不认宿主类型：截图上传、接口、会话落定、提示外观都归宿主的服务。
宿主做三件事：启动时 CCFeedbackInbox.shared.configure(服务)；入口钮挂 .ccCountBadge(inbox.unread)；设置页「意见反馈」行只挂红点（feedbackBadge: inbox.hasUnread），不写现值；sheet 里放 CCFeedbackBox，页头（✕）与「有填写先问」归宿主 sheet。
视觉件逐值移植胃之书 DesignSystem（分段、角标、输入面、主钮、原卡片、骨架），一律对内（CCFB 前缀），不与包内同名公开件相撞；字走 CCFBFont（胃之书系统字号表），不走包内 Font.cc。
本目录不引 Pow：主钮按压壳取包内 CCDesigin.CCButton，转圈期间的扫光是包内 shimmer。

成员清单
CCFeedbackService.swift: 公开契约。CCFeedbackCategory 三类 · CCFeedbackDraft（正文 ≤2000，端侧环境由意见箱填）· CCResolvedFeedback / CCFeedbackPage · CCFeedbackError（upload · submit）· CCFeedbackService 协议（appName · imageLimit（0 不收截图）· inviteShareText · inviteShareURL（缺省 CCStudio.shareURL ?? storeURL）· submit · resolved · unread · markSeen · toast 缺省走 AppHelper）· CCFeedbackInbox 未读单例（refresh 失败留旧值，markSeen 先清零再上报）。
CCFeedbackBox.swift: 公开入口 CCFeedbackBox(isDirty:onSubmitted:emptyArt:) 与草稿模型。「提出」：大标题（「向 %@ 提意见」）· 三类等宽胶囊 · 长文输入 · 截图格（PhotosPicker，≤ imageLimit）· 主钮 · 公开说明；草稿归容器、切段不丢；进「解决」段即 markSeen。
CCFeedbackResolved.swift: 「解决」段。分页器照胃之书 CCListDataScrollView（每页 10、加载更多冷却 2 s、失败退页、下拉刷新）；一条一张原卡片：类型胶囊 · 已修复 · 长日期 / 正文 6 行 / 头像与提出人，右侧淡绿大对勾压出卡沿；三张同形骨架卡与空态（插图由宿主给）。
CCFeedbackInvite.swift: 「邀请」段。进化路径插图（四节点渐大、终点成功绿对勾，入场描线一次，减弱动效直接成图）· 标题 · 两句主张 · <24h · 分享钮（系统分享：宿主一句话 + 服务的 inviteShareURL）。
CCFeedbackSegmented.swift: 分段栏（BellySegmented 极简态移植）：玻璃胶囊轨道、注水分宽、放不下横滑与两端渐隐、选中平胶囊 foreground × 0.06、按下即换、字后计数角标；不移植图标与跟手分页。
CCFeedbackBadge.swift: 计数角标（BellyCountBadge 移植）：危险色系统玻璃胶囊 · 等宽粗体 15 · 高 20 · 至少正圆 · 千起写 k；对外 CCCountBadge（SwiftUI，0 即不出）与 ccCountBadge(_:) 摆法（左端圆心落在钮右上角内缩 9，向右长），宿主入口钮一律用它。
CCFeedbackParts.swift: 视觉原子：近白键帽输入面与长文输入（聚焦托、剩余字数）、大号主钮（深色玻璃胶囊 58）、原卡片（圆角 20、双边双影）、空态（插图 240 · 两行字）。
CCFeedbackSkeleton.swift: 骨架（BellySkeleton 移植）：UIKit 块 + 图层平移扫光（随机时长与负延迟、离窗即摘、Reduce Motion 静止）、条 / 圆 / 段落、门槛 0.3 s 与淡换 0.2 s。
CCFeedbackTokens.swift: 数值层与字、文案入口；本目录其它文件不写魔法数字。文案在 ../Studio.xcstrings（feedback.*、common.submit、common.add，二十语）。

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
