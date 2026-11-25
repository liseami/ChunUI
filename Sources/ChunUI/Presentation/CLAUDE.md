# Presentation/
> L2 | 父级: ../../../CLAUDE.md

呈现门面层：sheet/alert/toast/导航的命令式唯一出口，宿主导航结构零感知。

成员清单
Apphelper.swift: AppHelper 单例门面——mada 触觉/presentSheet/dismissSheet/沉底 Alert/toast（路由经可注入 toastRouteResolver）/AppStore.requestReview
CCNav.swift: CCNav.pop 就地导航发现 + 包内 CCNav.present 是组件 UIKit 模态的唯一呈现口（锚点由调用方给）+ CCPhotoSelectMemory 选图记忆
TopCardPresenter.swift: 屏幕中央卡片呈现窗

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
