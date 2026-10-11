# Components/
> L2 | 父级: ../../../CLAUDE.md

CC 组件族：按钮/表单/卡片/呈现/媒体 40+ 件，全部主题驱动零业务。

成员清单
CCNeoButton.swift: 微拟物按钮五变体×三尺寸（圆角 height×0.38 连续圆，禁胶囊；async loading + 显式 public init）+ View.ccNeoChrome / ccNeoChromeCircle（圆仅输入坞发送特例）/ RoundedRectangle.ccButton + CCNeoPressStyle/CCListRowPressStyle；主钮质感对齐 Laper-app EmphasisEffect（1px 深一线 ring + 受光渐变 + 顶沿内高光只蒙上半）；CCSegmentedControl 复刻 17005:772（#f0f0f0 凹槽圆角矩形 + 选中白底 16% primary 洗拇指，高 56，行上禁 fieldCard）
CCButtons.swift: 按钮族（GlassButton/MetalGlassButton/GlassIconButton/CircleButton/返回钮，Pow glow/shake 按压）；CCDesigin.Button 无 icon 转发 CCNeoButton，有 icon 走 ccNeoChrome；pinkGlassButtonStyle / softButtonStyle 旧入口内部已归一 CCNeoSurface（圆角矩形，禁胶囊）
CCNeoCards.swift: CCAppleCard 连续圆角三级软阴影卡 + CCNeoInput + CCCuteTag/CCKeycapTag 胶囊标签
CCChatComposer.swift: 通用对话输入坞，1~6 行自长 + 正圆发送钮，running 时换停止；业务坞在宿主里包它
CCForms.swift: CCInput/CCTextArea/CCToggle/CCCheckbox/CCDatePicker 表单族；CCToggle = Kumo Switch 形制（扁 squircle 轨道 40×20 + 满高正方滑块双层阴影 + 1px ring 开态深一线，150ms ease-out，热区补足 44pt）
CCTexts.swift: CCText/CCTyperText 打字机
CCImages.swift: CCWebImage 内建 URLCache 加载器（CCImageLoader.custom 可整体接管）+ UserAvatar + CCAvatarFallback（宿主资产优先 SF 兜底）
CCLayout.swift: SubViewHeader/PageHeader/CCNavibarWithRightBtn 布局件
CCCommon.swift: ICON 图标映射 + CCEmptyView 旧入口
CCEmptyState.swift: 统一缺省态（插图资产由宿主提供）
CCPageHeader.swift: 编辑气质页头（标题+副标题槽+trailing 槽）
CCFloatingChrome.swift: 页面 chrome 范式（CCChromeBacking 双向模糊承托 + ccFloatingPageHeader）
CCNativeSheet.swift: 原生 UISheetPresentationController 深度调参 + CCSheetConfig 公开预设 + CCPresentationAnchor 窗口发现（脏态下拉确认）
CCEditSheetChrome.swift: 编辑 sheet 统一 chrome（X↔✓ 脏态切换）
CCBottomAlert.swift: 沉底双胶囊 Alert（CCAlertCenter + CCAlertWindow 置顶窗）
CCToast.swift: Kumo 叠放 toast（CCToastCenter 多张栈：结果顶换 loading/展开冻结倒计时；CCToastView 叠放编舞：最新在前、旧张缩 0.1 上探 12pt 对齐前张尺寸正文淡出、点整叠展开成列表、限 3 张可见、曲线 cubic-bezier(0.22,1,0.36,1)；卡片 = 状态色圆徽 + 正文 + 关闭钮进度环[冻结同暂停] + 图标色 3.33s 渐变；CCToastWindow 触摸只在叠层命中区 capsuleHitRect/气泡态接管）+ CCAqiBubbleToast + CCKeyboardWatcher
CCUploadToast.swift: 上传进度胶囊（UploadProgressCenter 字节级进度）
CCAqiBubbleTail.swift: 气泡几何原子——AqiBubbleTail 右下尖尾 + CCSpeechBubbleShape（Laper tooltip 法：气泡与底部中央尖尾一条闭合路径，两肋凹弯 + 圆尖，fill/stroke 连续无接缝）
CCSplitFlapText.swift: 机场翻牌板（React Bits SplitFlapText 移植：暗瓦上下半分体 + 前翻折下/后翻落定两相 3D 翻页 + 中缝铰链；随机字符序列错拍翻入落定目标，可多词循环；Reduce Motion 直落）
CCSkeleton.swift: Kumo SkeletonLine 骨架屏（CCBone 每条自带独立扫光：随机时长 1.3–1.7s + 随机相位[负延迟等价]、前景 8% ease-in-out 高光，整片不同步闪；CCBoneText 行宽各自随机末行更短；CCSkeleton 语义容器）
CCCardDeck.swift: Tinder 式无限轮转卡组容器
CCChipFlow.swift: 换行流布局 Layout
CCSettingRow.swift: 设置行原子（CCSettingRow/CCProTag/CCQuickAction）
CCIllustrationTile.swift: 插图动作瓦片
CCRainbowBar.swift: 彩虹进度条（12 色异速交织，TimelineView 取模）
CCBannerLine.swift: 横幅线条
CCLeatherStyle.swift: 皮革质感
CCTrackSeam.swift: 埋点依赖倒置座（CCTrack.onTap + .ccTrackTap）
CCSmoothCorner.swift: 连续曲率圆角（Figma smoothing：直边 → 三次贝塞尔 → 圆弧 → 对称贝塞尔；s = 0 普通圆角，s = 1 超椭圆）。path 给闭合轮廓；append / tail / split / solve 公开，供气泡在回落贝塞尔上切倒角
CCMicGrille.swift: 麦克风网罩。CCGrilleLayout.holes 给孔心（奇数行错开、中间字带不打孔）；CCGrilleLayout.image 与 CCMicGrille 把半透明暗孔叠在玻璃上，孔内阴影下移 0.75、模糊 1
CCGlassView.swift: UIKit 玻璃面。iOS 26 用 UIGlassEffect，18.6–25 用超薄磨砂；形走 SoftGlassShape，着色可空，materialized 关掉即退场。SwiftUI 玻璃仍走 ccGlassEffect
CCHoldTalk.swift: 按住说话的落点与弹簧。CCHoldZone 是中 / 取消 / 转文字；CCHoldSlab 给出整板、凹屏、提示行、孔阵、左右垫和按进度下移的框；zone 用板上沿和 12pt 迟滞判区；CCHoldSpring 阻尼比 1，升起 0.26、落下 0.2
CCVoiceScreen.swift: 凹屏点阵模型。列式声纹、熄点呼吸、转文字字行、3×5 点阵数字、开关机光圈。逐帧只改数组
CCVoiceScreenView.swift: 凹屏。暗色屏面、上沿内阴影、下沿唇边、斜向反光；点阵走 CCVoiceDots.metal，数字是同一套实心点
CCZoomTransition.swift: UIKit Zoom 英雄转场基建（锚点注册表：同一视图不留过期 id，source 无窗/空框/出窗返回 nil；CCAnchorMotion 解析仍在窗口中的来源框 + 临界阻尼弹簧，减弱动态效果退 0.2s ease-out；ccZoomSource 可空 id）
CCVideo.swift: 视频缩略/查看器（跟手拖拽回落）
CCCameraPicker.swift: 系统相机命令式出口（AppHelper.presentCamera → UIImage；无相机返回 false），与 CCPHPicker 并列
CCPHPicker.swift: 系统相册命令式出口（PHPicker → [PickedMedia]，出口挂 AppHelper）
PhotoSlector.swift: 照片选择器（选图时间记忆 CCPhotoSelectMemory）
SquareCropPicker.swift: 系统选图+正方裁剪
CCCamera.swift: 相机组件（权限文案走 CCStrings）
Camera/: 相机子系统（CameraViewModel/CameraPreviewView/FilteredCameraPreview/CameraFilter）
InAppBrowser.swift: 应用内浏览器（WKWebView + 玻璃关闭钮）
StreamingText.swift: 流式打字文本
ImageStackCarousel.swift: 图片堆叠轮播
GridBackground.swift: 网格背景
VideoBackground.swift: 视频背景
DisplayLinkView.swift: CADisplayLink 帧同步视图
ThinLine.swift: 细线分隔符

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
