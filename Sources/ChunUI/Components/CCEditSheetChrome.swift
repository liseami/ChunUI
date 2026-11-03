/**
 * [INPUT]: 依赖 CCEditSheetContext、CCChromeBacking、CCDesigin.GlassIconButton、PikaIcon、Color.cc/Font.cc
 * [OUTPUT]: 对外提供 CCEditSheetHeader——左标题 + 右液态玻璃 X/✓（脏且注册过保存才是 ✓）+ 顶部模糊承托
 * [POS]: DesignSystem 编辑 sheet 统一 chrome；右上角唯一合法关闭/保存钮 = GlassIconButton（与子页返回同制式）
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCEditSheetHeader（左标题 · 右液态玻璃 X↔✓ · 顶模糊）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public struct CCEditSheetHeader: View {
    let title: String

    public init(title: String) {
        self.title = title
    }

    @EnvironmentObject private var editSheet: CCEditSheetContext
    @State private var saving = false

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.cc.lgBold)
                .foregroundStyle(Color.cc.foreground)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailingButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(alignment: .top) {
            CCChromeBacking(edge: .top)
                .frame(height: 96)
                .offset(y: -20)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        if saving {
            ProgressView()
                .controlSize(.regular)
                .frame(
                    width: CCDesigin.GlassIconButtonMetrics.size,
                    height: CCDesigin.GlassIconButtonMetrics.size
                )
                .softGlassStyle(.circle)
        } else {
            CCDesigin.GlassIconButton(
                icon: savesOnTap ? "check-tick-single" : PikaIcon.Name.close
            ) {
                AppHelper.shared.mada(.soft)
                if savesOnTap {
                    saving = true
                    Task {
                        await editSheet.commitSave()
                        saving = false
                    }
                } else {
                    editSheet.requestClose()
                }
            }
            .accessibilityLabel(
                savesOnTap
                    ? CCStrings.current.save
                    : CCStrings.current.cancel
            )
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: savesOnTap)
        }
    }

    /// 脏且注册过保存：右上是 ✓，点即保存；否则是 ✕，脏时关前先问
    private var savesOnTap: Bool { editSheet.isDirty && editSheet.canSave }
}

/// 脏态同步：任意 Equatable 表单快照变化即 mark dirty
public struct CCEditSheetDirtyModifier<Value: Equatable>: ViewModifier {
    @EnvironmentObject private var editSheet: CCEditSheetContext
    let value: Value
    let baseline: Value

    public func body(content: Content) -> some View {
        content
            .onAppear { editSheet.setDirty(value != baseline) }
            .onChange(of: value) { _, new in
                editSheet.setDirty(new != baseline)
            }
    }
}

extension View {
    /// 绑定脏态：value 偏离 baseline 时右上角变 ✓，下拉触发三选一
    public func ccEditSheetDirty<Value: Equatable>(_ value: Value, baseline: Value) -> some View {
        modifier(CCEditSheetDirtyModifier(value: value, baseline: baseline))
    }

    /// 注册保存闭包（返回 true 关闭）
    public func ccEditSheetSave(_ handler: @escaping () async -> Bool) -> some View {
        modifier(CCEditSheetSaveModifier(handler: handler))
    }
}

private struct CCEditSheetSaveModifier: ViewModifier {
    @EnvironmentObject private var editSheet: CCEditSheetContext
    let handler: () async -> Bool

    func body(content: Content) -> some View {
        content.onAppear {
            editSheet.registerSave(handler)
        }
    }
}
