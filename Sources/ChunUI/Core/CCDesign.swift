/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCDesign.swift                                   ║
 * ║                    设计系统 UI 组件库 - 命名空间入口                          ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: SwiftUI
 * [OUTPUT]: CCDesigin 命名空间 + 组件 Preview
 * [POS]: DesignSystem 核心入口，提供 CCDesigin 命名空间
 *
 * 组件拆分:
 * - CCButtons.swift: 按钮组件 (Button[.large/.medium/.small, .primary/.secondary], CCTagButton, CircleButton, 返回按钮)
 * - CCForms.swift: 表单组件 (CCTextField, CCNumberField, CCFormRow, CCEditLayout)
 * - CCTexts.swift: 文本组件 (CCText, CCTyperText)
 * - CCImages.swift: 图片组件 (CCWebImage, UserAvatar)
 * - CCLayout.swift: 布局组件 (SubViewHeader, PageHeader, CCNavibarWithRightBtn)
 * - CCCommon.swift: 通用组件 (ICON, CCEmptyView)
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCDesigin 命名空间
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 设计系统 UI 组件命名空间
///
/// 所有业务 UI 组件通过 `CCDesigin.*` 访问
/// 使用方式: `CCDesigin.Button("确认") { }` 或 `CCDesigin.Button("取消", variant: .secondary) { }`
public enum CCDesigin {}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Preview
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 30) {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 按钮组件 (Button Components)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            VStack(alignment: .leading, spacing: 16) {
                Text("按钮组件")
                    .ccText(font: .cc.title3Bold, color: .cc.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 20) {
                    // ━━━ 大按钮 (主要) ━━━
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Button(.large, .primary) - 主要操作")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        CCDesigin.Button("开始体验") {}
                    }

                    // ━━━ 中按钮 + 图标组合 ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Button(.medium) + CircleButton")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        HStack(spacing: 12) {
                            CCDesigin.CircleButton(icon: "arrow-left") {}
                            CCDesigin.Button("确认保存", size: .medium) {}
                        }
                    }

                    // ━━━ Primary vs Secondary ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary vs Secondary")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        HStack(spacing: 12) {
                            CCDesigin.Button("取消", size: .medium, variant: .secondary) {}
                            CCDesigin.Button("确认", size: .medium) {}
                        }
                    }

                    // ━━━ 禁用态 ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("禁用态")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        CCDesigin.Button("处理中...", size: .medium, enable: false) {}
                    }

                    // ━━━ 圆形图标按钮 ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CircleButton - 图标按钮")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        HStack(spacing: 12) {
                            CCDesigin.CircleButton(icon: "plus-default") {}
                            CCDesigin.CircleButton(icon: "arrow-left") {}
                            CCDesigin.CircleButton(icon: "home_search") {}
                        }
                    }

                    // ━━━ 小按钮 ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Button(.small) - 小型按钮")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        HStack(spacing: 12) {
                            CCDesigin.Button("美食相机", icon: "plus-default", size: .small) {}
                            CCDesigin.Button("更多", size: .small, variant: .secondary) {}
                        }
                    }

                    // ━━━ 标签按钮 ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CCTagButton - 标签按钮")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        HStack(spacing: 8) {
                            CCDesigin.CCTagButton(icon: "plus-default", text: "添加") {}
                            CCDesigin.CCTagButton(icon: "home_search", text: "搜索") {}
                        }
                    }

                    // ━━━ 返回按钮 ━━━
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CircularBackButton - 返回按钮")
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        HStack(spacing: 12) {
                            CCDesigin.CircularBackButton(autoLayout: false) {}
                            CCDesigin.TabBarStyleBackButton() {}
                        }
                    }
                }
            }

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 图片组件 (Image Components)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            VStack(alignment: .leading, spacing: 16) {
                Text("图片组件")
                    .ccText(font: .cc.title3Bold, color: .cc.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    Text("CCWebImage & UserAvatar")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        CCAvatarFallback()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        CCDesigin.UserAvatar(str: "", userId: "", size: 56)
                    }
                }
            }

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 文本组件 (Text Components)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            Group {
                Text("文本组件")
                    .ccText(font: .cc.title3Bold, color: .cc.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    Text("CCTyperText - 打字机效果")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    CCDesigin.CCTyperText("这是一段模拟AI打字效果的文本", duration: 2)
                        .padding()
                        .background(Color.cc.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("CCText - 占位文本")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    CCDesigin.CCText(str: nil, length: 8)
                        .padding()
                        .background(Color.cc.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 图标组件 (Icon Components)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            Group {
                Text("图标组件")
                    .ccText(font: .cc.title3Bold, color: .cc.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 20) {
                    CCDesigin.ICON(systemName: "star.fill", size: 32, color: .cc.chartFat)
                    CCDesigin.ICON(imageName: "home_search", size: 28, color: .cc.mutedForeground)
                    CCDesigin.ICON(imageName: "plus-default", size: 24, color: .cc.foreground)
                }
            }

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 表单组件 (Form Components)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            FormComponentsPreview()

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // MARK: - 空状态组件 (Empty State)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            Group {
                Text("空状态组件")
                    .ccText(font: .cc.title3Bold, color: .cc.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CCDesigin.CCEmptyView(
                    image: "empty_card",
                    title: "暂无卡牌收藏",
                    subline: "记录餐食获得点数，即可开始集换式卡牌之旅。"
                )
            }

            Spacer().frame(height: 100)
        }
        .padding()
    }
    .background(Color.cc.background.ignoresSafeArea())
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 表单组件 Preview 子视图
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct FormComponentsPreview: View {
    @State private var inputText = ""
    @State private var textareaText = ""
    @State private var toggleOn = false
    @State private var checkboxChecked = false
    @State private var selectedDate = Date()

    var body: some View {
        Group {
            Text("表单组件")
                .ccText(font: .cc.title3Bold, color: .cc.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 20) {
                // ━━━ CCInput 单行输入 ━━━
                VStack(alignment: .leading, spacing: 8) {
                    Text("CCInput - 单行输入框")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                    CCDesigin.CCInput(placeholder: "请输入内容...", text: $inputText)
                }

                // ━━━ CCTextArea 多行输入 ━━━
                VStack(alignment: .leading, spacing: 8) {
                    Text("CCTextArea - 多行输入框")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                    CCDesigin.CCTextArea(placeholder: "请输入详细内容...", text: $textareaText)
                }

                // ━━━ CCToggle 开关 ━━━
                VStack(alignment: .leading, spacing: 8) {
                    Text("CCToggle - 开关组件")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                    HStack {
                        Text("通知开关")
                            .ccText(font: .cc.body, color: .cc.foreground)
                        Spacer()
                        CCDesigin.CCToggle(isOn: $toggleOn)
                    }
                    .padding()
                    .background(Color.cc.card)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // ━━━ CCCheckbox 复选框 ━━━
                VStack(alignment: .leading, spacing: 8) {
                    Text("CCCheckbox - 复选框")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                    HStack(spacing: 16) {
                        CCDesigin.CCCheckbox(isChecked: $checkboxChecked, label: "同意用户协议")
                        CCDesigin.CCCheckbox(isChecked: .constant(true), label: "已选中")
                    }
                }

                // ━━━ CCDatePicker 日期选择器 ━━━
                VStack(alignment: .leading, spacing: 8) {
                    Text("CCDatePicker - 日历日期选择器")
                        .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                    CCDesigin.CCDatePicker(selectedDate: $selectedDate)
                }
            }
        }
    }
}
#endif
