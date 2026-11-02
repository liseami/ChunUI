# 组件逐类参考

## 设计令牌（一切组件的地基）

```swift
Color.cc.primary / .background / .card / .panel / .muted / .accent / .border / .destructive / .success …
Font.cc.sm(13) / .base(17) / .lg(24)（+Bold）   // 三梯度字号铁律，禁第四个字号
CGFloat.cc.base(16) / .sm(8) / .hairline(0.5)
Text("…").ccText(font: .cc.base, color: .cc.foreground)   // 文字统一写法
```

## 按钮

| 组件 | 用途 | 关键参数 |
|---|---|---|
| `CCNeoButton("标题") { await … }` | 主力微拟物钮（圆角 height×0.38，禁胶囊）；质感对齐 Laper EmphasisEffect | variant: .primary/.secondary/.ghost/.outline/.danger · size: .large/.medium/.small · icon(pika 名) · fullWidth · accent 覆色 |
| `CCSegmentedControl(selection:items:)` | 56pt 凹槽圆角矩形分段（Figma 772×2 高，禁胶囊）；选中 16% 主题色洗拇指 | items: `[(Value, String)]` |
| `View.ccNeoChrome(_:height:)` | 自定义内容套 CCNeoButton 同款圆角矩形质感 | variant · height · disabled · accent |
| `View.ccNeoChromeCircle(_:diameter:)` | 同款质感正圆（仅输入坞发送特例） | variant · diameter · disabled · accent |
| `CCDesigin.GlassIconButton(icon:)` | 正圆液态玻璃图标钮（iOS26 Liquid Glass/以下微拟物） | tint · size: .regular(50)/.small(34) |
| `CCDesigin.CircleButton(icon:)` | 玻璃圆钮兼容入口 | |
| `CCDesigin.CircularBackButton` / `TabBarStyleBackButton` | 返回钮（无 action 自动 CCNav.pop） | |
| `.softGlassStyle(.capsule)` | 任意视图玻璃底 | .circle/.capsule/.roundedRectangle(r)/.unevenRoundedRectangle |
| `.pinkGlassButtonStyle()` | 品牌色玻璃按压样式 | |

## 表单

```swift
CCDesigin.CCInput(placeholder:text:)        // 单行 36pt
CCDesigin.CCTextArea(placeholder:text:)     // 多行 112pt
CCDesigin.CCToggle(isOn:)                   // 44×24 主题色胶囊
CCDesigin.CCCheckbox(isChecked:label:)
CCChatComposer(placeholder:text:running:onSend:onStop:)  // 对话输入坞（自长 + 发送 / 停止圆钮）
CCNeoInput(placeholder:text:icon:secure:)   // 微拟物输入（卡片底+主题色焦点环；secure 为口令框）
CCSegmentedControl(selection:items:)        // 56pt 凹槽胶囊分段
CCDesigin.CCDatePicker                       // 日历网格
```

## 卡片与标签

```swift
CCAppleCard(shadowLevel: 1..3) { 内容 }      // 连续圆角+发丝边+三级软阴影；修饰符版 .appleCard(radius:)
VStack { rows }.ccGroupCard()               // 设置组卡
CCCuteTag("128 人", icon:)                   // 统计胶囊（24pt 不透明底+微影）
CCKeycapTag("BETA", color:)                 // 键帽标签（渐变键面+3px 厚底）
CCSettingRow(icon:title:trailing:)          // 设置行；trailing: .chevron/.badge/.pro/.text()/.value()/.none
CCFormSection(title?, footer:) { CCFormRow(title, icon:, value:, divider:) {} }  // 设置分组卡（设置类页面一律用它）；CCFormRow 可给任意前导 + leadingWidth、附件放 accessory、CCFormCheck 单选勾；几何 CCFormTokens
CCProTag() / CCQuickAction(icon:title:)
CCChipFlow(spacing:) { chips }              // 换行流布局
CCCardDeck(deck:$items) { item, i, isTop in card }  // Tinder 无限轮转卡组（甩出→归底）
```

## 页面 chrome

```swift
page.ccFloatingPageHeader { CCPageHeader(title: "标题", subtitle: "副标题") { trailing } }
// 内容从模糊承托下自由滚过；CCChromeBacking(edge: .top/.bottom) 是承托原子
// 页头规格：title2Bold 标题 + footnote 灰阶副标题（或 subtitleView 自定义槽）+ trailing 槽
CCEmptyState(kind:message:detail:compact:)  // 统一空态（插图从宿主资产取）
VariableBlurView                             // 渐进模糊原子
```

## 反馈

见 usage/presentation.md：CCToastCenter / CCAlertCenter / CCUploadToast（字节级上传进度胶囊 UploadProgressCenter）/ CCSkeleton。

## 媒体

```swift
CCDesigin.CCWebImage(str:role:)   // 网络图（.media 内缩灰块占位 / .avatar 缺省图铺满）
CCDesigin.UserAvatar(str:userId:size:)
CCVideoThumb / CCVideoViewerController   // 视频首帧+跟手查看器
CCCamera 相机子系统 / SquareCropPicker / presentPHPicker
ImageStackCarousel / VideoBackground
```

## 文本与 Markdown

`CCDesigin.CCTyperText` / `CCStreamingText` / `MarkdownText(_:font:color:)`。

## 图标

`PikaIcon("search-default", size: 18, color: .cc.mutedForeground)`——1225 枚 24×24 stroke 模板矢量随包；常用名有 `PikaIcon.Name.*` 常量层防拼写。
