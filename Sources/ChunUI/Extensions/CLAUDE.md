# Extensions/
> L2 | 父级: ../../../CLAUDE.md

通用系统扩展子集（自宿主提取时业务函数已肃清）。

成员清单
String+.swift: 字符串工具 · Text+.swift: 文本修饰
Then.swift: 线程中立的同步 with/do/then 配置；协议与方法显式 nonisolated，NSObject、集合及几何类型遵循保持原签名，通用配置不继承包默认 MainActor。
CGRect/CGSize/CGAffineTransform+Extensions.swift: 几何工具 · Float+.swift: 数值工具
UIApplication+Extensions.swift: 应用/窗口工具 · UIScreen+.swift: cc_active 取屏唯一出口 · UIScreen+Extensions.swift: 屏幕度量
UIImage+.swift: 图像处理 · UIView+Extensions.swift: 视图工具 · PHAsset+Extensions.swift: 相册资产工具

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
