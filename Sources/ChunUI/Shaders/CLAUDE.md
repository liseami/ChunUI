# Shaders/
> L2 | 父级: ../../../CLAUDE.md

Metal 着色器层：SPM 自动编译进 Bundle.module 的 default.metallib。

成员清单
CCShaders.swift: Swift 侧唯一取用门面（ShaderLibrary.bundle(.module)；禁 ShaderLibrary.default）
Aurora.metal: 极光 · GlimmSweep.metal: 扫光（citrus 余弦调色+虹彩+菲涅尔） · FractalTextures.metal: 九分形 halftone 点阵
DustDissolve.metal: 粒子消散 compute 管线 · MetaBalls.metal / Silk.metal / Beams.metal / Noise.metal / Sinebow.metal / card.metal / ColorBendsAurora.metal: 各特效片元
CCGradientWaves.metal: 发言涟漪海面（ccGradientWavesVertex 全屏三角 + ccGradientWavesFragment 等离子体 raymarch **70 步**倒挂[40 步糊成雾]、原版参数基线抬振幅 3.4 + 能量调制、浪心轴色带（波谷 wave/波峰 crest）+ smoothstep 雾层级、**顶 1/3 视口压缩**（34% 屏高虚拟画布：完整上→下构图整体压入顶 1/3，不裁剪不改向；0.30→0.36 兜底收零。禁回退成屏幕裁剪——裁剪会切掉中段丝绸层只剩远景平块），预乘 alpha；经典管线专供 Effects/CCGradientWavesView 的 MTKView 渲染器，非 stitchable）
CCCloudField.metal: Cromma 体积云（ccCloudFieldVertex 全屏三角 + ccCloudFieldFragment 元球骨架 × 三层絮状 × 指数透射，预乘 alpha；扫光 uniform 由 CPU 关死；专供 Effects/CCCloudField，不画点阵/极光）
CCVoiceDots.metal: 按住说话凹屏点阵（ccVoiceDotsVertex 全屏三角 + ccVoiceDotsFragment 查八邻画实心点与辉光，光圈压扁、中线亮线；专供 Components/CCVoiceScreenView）

[PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
