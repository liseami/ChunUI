# Effects/
> L2 | 父级: ../../../CLAUDE.md

视觉特效层：shader 消费侧组件，全部经 CCShaders 取包内 Metal 库。

成员清单
CCAuroraLayer.swift: AI 工作态底部极光（相位累计器，暂停零帧更新；显式 public init）
GeneratingCover.swift: 「生成中」四层质感（中性底+实体色氤氲+7pt 呼吸点阵+对表白流光）
CCFractalFloor.swift: 九分形族点阵地板（Julia/Newton/Mandelbrot…，edge 贴顶/贴底渐隐）
CCSweepLight.swift: 转场扫光协调器（穿透覆盖窗 + GlimmSweep.metal）
ParticleDissolve.swift: 窗口级粒子消散（快照 + 独立 Metal 层 + 按需 DisplayLink）
HolographicCardEffects.swift: 全息卡片效果族
MetaBallsBackground.swift: 元球背景
SilkView.swift: 丝绸效果
BeamsView.swift: 光束效果
ColorBendsView.swift: 颜色弯曲
RandomNoiseShader.swift: 随机噪声
RainbowLineView.swift: 彩虹线条
AurorabackGround.swift: 极光背景（旧版氛围层）
CCCardSwap.swift: 卡堆轮换（React Bits CardSwap 移植）双形态——diagonal 斜置 3D（x/y 阶梯 + z 纵深缩放 + 斜切）/ centered 居中同心叠（后卡每层缩 5% 上探微探头，零透视零横移，占位仅本尺寸不撑版面）；flyInIntro 开场：全卡金角散布四面八方、由深到浅 55ms 错拍弹簧飞入（超深卡落位即隐入堆中），随后常速轮换；每拍前卡坠出→群卡弹簧上位→前卡沉底归尾；任意张数只渲染前 visibleDepth 深度；Reduce Motion 直落静止
CCParticleText.swift: 粒子聚字（React Bits ParticleText 移植：灰度位图采样字形 → 散开 easeOutCubic 错拍聚合 → 呼吸漂浮 + 拖动斥力；调色板 12 桶批量 Path 填充禁逐粒 fill；Reduce Motion 直落）
CCGradientWavesView.swift: 倒挂涟漪氛围层（MTKView 真管线 30fps 透明混合；speech 0…1 能量经渲染器攻快 0.5/衰慢 0.1 包络平滑；配色三层拉满对比 horizon=primary 混黑 15%/wave=混白 30%/crest=纯白，**禁混背景淡化——那是隐身元凶**；Reduce Motion 暂停；管线装配失败 DEBUG 报错不静默）
CCCloudField.swift: Cromma 舷窗白云 IsolatedCloudMTKView（30fps 原生 DPR；ccAtmospherePaused / 离窗才 pause；云连续慢卷无扫光）。点阵/极光不进这层
CCSkyHeroCard.swift: 首页英雄卡（点阵 + 极光，云已裁；点阵步长 10pt / 圆 1.8pt；Cromma 天蓝 #3B6CFF blur56/multiply，Cromma mask 同构；侧栏跟手暂停氛围；禁宿主粉）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
