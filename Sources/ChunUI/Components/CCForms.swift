/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                          CCForms.swift                                    ║
 * ║                         表单输入组件库                                      ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 *
 * [INPUT]: CCDesignSystem 主题、SwiftUI、Core/CCComponentText（日历表头与月份格式，Components 表二十语）
 * [OUTPUT]: CCInput, CCTextArea, CCToggle, CCCheckbox, CCDatePicker,
 *           CCTextField, CCNumberField, CCFormRow, CCEditLayout
 * [POS]: DesignSystem/Compents 表单组件，被编辑页面消费
 *
 * 新组件 (Figma 设计规范):
 * - CCInput: 单行输入 (h36, r6, 边框+阴影)
 * - CCTextArea: 多行输入 (h112, r6)
 * - CCToggle: 开关 (44x24, 粉色胶囊)
 * - CCCheckbox: 复选框 (16x16, r4, 粉色勾选)
 * - CCDatePicker: 日期选择器 (日历网格)
 *
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 设计令牌 (Figma 规格)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum FormTokens {
    // 输入框
    static let inputHeight: CGFloat = 36
    static let inputCornerRadius: CGFloat = 12
    static let textareaHeight: CGFloat = 112

    // 开关
    // Kumo Switch lg 档几何：轨道 40×20，滑块 = 满高正方，开启位移 = 宽 − 高
    static let toggleWidth: CGFloat = 40
    static let toggleHeight: CGFloat = 20

    // 复选框
    static let checkboxSize: CGFloat = 16
    static let checkboxCornerRadius: CGFloat = 4

    // 日期选择器
    static let dayCellSize: CGFloat = 36
    static let calendarCornerRadius: CGFloat = 12

    // 边框颜色
    static let borderColor = Color(hex: "#d4d4d4")

    // 阴影
    static func inputShadow() -> some View {
        Color.clear
            .shadow(color: .black.opacity(0.1), radius: 1.5, x: 0, y: 1)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 表单输入验证类型
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    enum CCTextFieldValidationType {
        case none
        case nonEmpty
        case number
        case nonNumber
        case email
        case custom((_ value: String) -> Bool)

        func validate(_ value: String) -> Bool {
            switch self {
            case .none:
                return true
            case .nonEmpty:
                return !value.isEmpty
            case .number:
                let regex = #"^\d*\.?\d*$"#
                return value.range(of: regex, options: .regularExpression) != nil && !value.isEmpty
            case .nonNumber:
                let regex = #"^[^\d]+$"#
                return value.range(of: regex, options: .regularExpression) != nil && !value.isEmpty
            case .email:
                let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
                return value.range(of: regex, options: .regularExpression) != nil
            case .custom(let validator):
                return validator(value)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCInput 单行输入框 (Figma)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 单行输入框
    /// - 高度: 36pt
    /// - 圆角: 6pt
    /// - 边框: #d4d4d4
    /// - 阴影: 双层微妙阴影
    struct CCInput: View {
        let placeholder: String
        @Binding var text: String
        var isDisabled: Bool = false

        public init(placeholder: String, text: Binding<String>, isDisabled: Bool = false) {
            self.placeholder = placeholder
            self._text = text
            self.isDisabled = isDisabled
        }

        @FocusState private var isFocused: Bool

        public var body: some View {
            TextField(placeholder, text: $text)
                .ccText(font: .cc.body, color: isDisabled ? .cc.mutedForeground : .cc.foreground)
                .padding(.horizontal, 12)
                .frame(height: FormTokens.inputHeight)
                .background(
                    RoundedRectangle(cornerRadius: FormTokens.inputCornerRadius)
                        .fill(Color.cc.card)
                        .shadow(color: .black.opacity(0.1), radius: 1.5, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FormTokens.inputCornerRadius)
                        .stroke(isFocused ? Color.cc.primary : FormTokens.borderColor, lineWidth: 1)
                )
                .focused($isFocused)
                .disabled(isDisabled)
                .tint(.cc.primary)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCTextArea 多行输入框 (Figma)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 多行输入框
    /// - 高度: 112pt
    /// - 圆角: 6pt
    /// - 边框: #d4d4d4
    struct CCTextArea: View {
        let placeholder: String
        @Binding var text: String
        var isDisabled: Bool = false

        public init(placeholder: String, text: Binding<String>, isDisabled: Bool = false) {
            self.placeholder = placeholder
            self._text = text
            self.isDisabled = isDisabled
        }

        @FocusState private var isFocused: Bool

        public var body: some View {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .ccText(font: .cc.body, color: .cc.mutedForeground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }

                // 文本编辑器
                TextEditor(text: $text)
                    .ccText(font: .cc.body, color: isDisabled ? .cc.mutedForeground : .cc.foreground)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .frame(height: FormTokens.textareaHeight)
            .background(
                RoundedRectangle(cornerRadius: FormTokens.inputCornerRadius)
                    .fill(Color.cc.card)
                    .shadow(color: .black.opacity(0.1), radius: 1.5, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FormTokens.inputCornerRadius)
                    .stroke(isFocused ? Color.cc.primary : FormTokens.borderColor, lineWidth: 1)
            )
            .focused($isFocused)
            .disabled(isDisabled)
            .tint(.cc.primary)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCToggle 开关组件（Cloudflare Kumo Switch 形制，Laper LaperToggle 同构）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// Kumo Switch：扁 squircle 轨道（40×20）+ 满高正方滑块 + 1px ring，150ms ease-out 滑动
    /// 开 = primary 底 + 深一线 ring（混 10% 黑，与强调钮同一条配方）；关 = sidebarAccent 底 + border ring
    /// 滑块恒 background 白，双层阴影（边缘一圈 + 下沉）；颜色只认设计系统 token
    struct CCToggle: View {
        @Binding var isOn: Bool
        var isDisabled: Bool = false

        public init(isOn: Binding<Bool>, isDisabled: Bool = false) {
            self._isOn = isOn
            self.isDisabled = isDisabled
        }

        private var trackW: CGFloat { FormTokens.toggleWidth }
        private var trackH: CGFloat { FormTokens.toggleHeight }
        /// squircle：连续曲率圆角（Kumo corner-shape: squircle 的 SwiftUI 等价）
        private var corner: CGFloat { trackH * 0.45 }

        public var body: some View {
            SwiftUI.Button {
                guard !isDisabled else { return }
                AppHelper.shared.mada(.light)
                withAnimation(.easeOut(duration: 0.15)) {
                    isOn.toggle()
                }
            } label: {
                ZStack(alignment: .leading) {
                    // 轨道：扁平纯色 + 1px ring（开启态 ring 比底色深一线）
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(isOn ? Color.cc.primary : Color.cc.sidebarAccent)
                        .overlay {
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .strokeBorder(
                                    isOn ? Color.cc.primary.mix(with: .black, amount: 0.10) : Color.cc.border,
                                    lineWidth: 1
                                )
                        }
                        .frame(width: trackW, height: trackH)

                    // 滑块：满高正方，双层阴影（0 0 1 0.5 边缘圈 + 0 1 2 下沉）
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.cc.background)
                        .frame(width: trackH, height: trackH)
                        .shadow(color: .black.opacity(0.12), radius: 0.5, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
                        .offset(x: isOn ? trackW - trackH : 0)
                }
                // 触控热区补足 44pt，视觉不变
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isDisabled ? 0.5 : 1)
            .animation(.easeOut(duration: 0.15), value: isOn)
            .accessibilityAddTraits(.isToggle)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCCheckbox 复选框组件 (Figma)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 自定义复选框
    /// - 尺寸: 16x16
    /// - 圆角: 4pt
    /// - 选中: 粉色填充 + 白色勾选
    struct CCCheckbox: View {
        @Binding var isChecked: Bool
        var label: String? = nil
        var isDisabled: Bool = false

        public init(isChecked: Binding<Bool>, label: String? = nil, isDisabled: Bool = false) {
            self._isChecked = isChecked
            self.label = label
            self.isDisabled = isDisabled
        }

        public var body: some View {
            SwiftUI.Button {
                guard !isDisabled else { return }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isChecked.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    // 复选框
                    ZStack {
                        RoundedRectangle(cornerRadius: FormTokens.checkboxCornerRadius)
                            .fill(isChecked ? Color.cc.primary : Color.cc.card)
                            .frame(width: FormTokens.checkboxSize, height: FormTokens.checkboxSize)

                        RoundedRectangle(cornerRadius: FormTokens.checkboxCornerRadius)
                            .stroke(isChecked ? Color.cc.primary : FormTokens.borderColor, lineWidth: 1)
                            .frame(width: FormTokens.checkboxSize, height: FormTokens.checkboxSize)

                        // 勾选图标
                        if isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }

                    // 标签
                    if let label = label {
                        Text(label)
                            .ccText(font: .cc.body, color: isDisabled ? .cc.mutedForeground : .cc.foreground)
                    }
                }
            }
            .buttonStyle(.plain)
            .opacity(isDisabled ? 0.5 : 1)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CCDatePicker 日期选择器 (Figma)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    /// 日历日期选择器
    /// - 日期格子: 36x36
    /// - 选中: 粉色圆形背景
    /// - 范围选择: 黄色背景
    struct CCDatePicker: View {
        @Binding var selectedDate: Date
        var rangeStart: Date? = nil
        var rangeEnd: Date? = nil

        @State private var currentMonth: Date = Date()

        private let calendar = Calendar.current
        private let daysOfWeek = CCComponentText.t("datePicker.weekdays").components(separatedBy: ",")

        public var body: some View {
            VStack(spacing: 16) {
                // ━━━ 月份导航 ━━━
                HStack {
                    SwiftUI.Button {
                        withAnimation { previousMonth() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.cc.foreground)
                    }

                    Spacer()

                    Text(monthYearString)
                        .ccText(font: .cc.bodyBold, color: .cc.foreground)

                    Spacer()

                    SwiftUI.Button {
                        withAnimation { nextMonth() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.cc.foreground)
                    }
                }
                .padding(.horizontal, 8)

                // ━━━ 星期标题 ━━━
                HStack(spacing: 0) {
                    ForEach(daysOfWeek.indices, id: \.self) { index in
                        Text(daysOfWeek[index])
                            .ccText(font: .cc.footnote, color: .cc.mutedForeground)
                            .frame(width: FormTokens.dayCellSize, height: FormTokens.dayCellSize)
                    }
                }

                // ━━━ 日期网格 ━━━
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(FormTokens.dayCellSize), spacing: 0), count: 7), spacing: 0) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
                            Color.clear
                                .frame(width: FormTokens.dayCellSize, height: FormTokens.dayCellSize)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: FormTokens.calendarCornerRadius)
                    .fill(Color.cc.card)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }

        // ━━━ 日期单元格 ━━━
        @ViewBuilder
        private func dayCell(for date: Date) -> some View {
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let isInRange = isDateInRange(date)
            let isToday = calendar.isDateInToday(date)

            SwiftUI.Button {
                withAnimation(.spring(response: 0.2)) {
                    selectedDate = date
                }
            } label: {
                Text("\(calendar.component(.day, from: date))")
                    .ccText(
                        font: isSelected ? .cc.bodyBold : .cc.body,
                        color: isSelected ? .white : (isToday ? .cc.primary : .cc.foreground)
                    )
                    .frame(width: FormTokens.dayCellSize, height: FormTokens.dayCellSize)
                    .background(
                        Group {
                            if isSelected {
                                Circle().fill(Color.cc.primary)
                            } else if isInRange {
                                Rectangle().fill(Color.cc.chartCarbs.opacity(0.3))
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }

        // ━━━ 辅助计算 ━━━
        private var monthYearString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = CCComponentText.t("datePicker.monthFormat")
            return formatter.string(from: currentMonth)
        }

        private var daysInMonth: [Date?] {
            guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
                  let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
            else { return [] }

            let firstWeekday = calendar.component(.weekday, from: firstDay)
            var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

            for day in range {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                    days.append(date)
                }
            }

            return days
        }

        private func previousMonth() {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }

        private func nextMonth() {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }

        private func isDateInRange(_ date: Date) -> Bool {
            guard let start = rangeStart, let end = rangeEnd else { return false }
            return date >= start && date <= end
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 通用文本输入组件 (Legacy)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCTextField: View {
        let label: String
        let placeholder: String
        @Binding var text: String
        let validationType: CCTextFieldValidationType
        @Binding var isValid: Bool
        let keyboardType: UIKeyboardType
        let errorMessage: String?
        /// section 最后一行传 false，避免组底多一条发丝线
        var showsDivider: Bool = true

        public init(
            label: String,
            placeholder: String,
            text: Binding<String>,
            validationType: CCTextFieldValidationType = .none,
            isValid: Binding<Bool>? = nil,
            keyboardType: UIKeyboardType = .default,
            errorMessage: String? = nil,
            showsDivider: Bool = true
        ) {
            self.label = label
            self.placeholder = placeholder
            self._text = text
            self.validationType = validationType
            self._isValid = isValid ?? .constant(true)
            self.keyboardType = keyboardType
            self.errorMessage = errorMessage
            self.showsDivider = showsDivider
        }

        public var body: some View {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Text(label)
                        .ccText(font: .cc.callout, color: .cc.foreground)
                        .frame(maxWidth: 60, alignment: .leading)

                    TextField(placeholder, text: $text)
                        .ccText(font: .cc.bodyBold, color: isValid ? .cc.secondaryForeground : .cc.destructive)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .tint(.cc.foreground)
                        .keyboardType(keyboardType)
                        .onChange(of: text) { _, newValue in
                            isValid = validationType.validate(newValue)
                        }

                    if !isValid && errorMessage != nil {
                        Text(errorMessage!)
                            .ccText(font: .cc.footnote, color: .cc.destructive)
                    }
                }
                .padding(.all, 16)
                .overlay(alignment: .bottom) {
                    if showsDivider { ThinLine() }
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 数值输入组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCNumberField<T: BinaryFloatingPoint>: View {
        let label: String
        let placeholder: String
        @Binding var value: T
        let validationType: CCTextFieldValidationType
        @Binding var isValid: Bool
        let errorMessage: String?

        @State private var textValue: String = ""

        public init(
            label: String,
            placeholder: String,
            value: Binding<T>,
            validationType: CCTextFieldValidationType = .number,
            isValid: Binding<Bool>? = nil,
            errorMessage: String? = nil
        ) {
            self.label = label
            self.placeholder = placeholder
            self._value = value
            self.validationType = validationType
            self._isValid = isValid ?? .constant(true)
            self.errorMessage = errorMessage
            self._textValue = State(initialValue: String(format: "%g", Double(value.wrappedValue)))
        }

        public var body: some View {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Text(label)
                        .ccText(font: .cc.callout, color: .cc.foreground)
                        .frame(maxWidth: 60, alignment: .leading)

                    TextField(placeholder, text: $textValue)
                        .onChange(of: textValue) { _, newValue in
                            if let doubleValue = Double(newValue),
                               let typedValue = T(exactly: doubleValue)
                            {
                                value = typedValue
                            }
                            isValid = validationType.validate(newValue)
                        }

                    if !isValid && errorMessage != nil {
                        Text(errorMessage!)
                            .ccText(font: .cc.footnote, color: .cc.destructive)
                    }
                }
                .padding(.all, 16)
                .overlay(alignment: .bottom) {
                    ThinLine()
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 通用表单行组件
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCFormRow<Content: View>: View {
        let label: String
        var showsDivider: Bool = true
        let content: Content

        public init(label: String, showsDivider: Bool = true, @ViewBuilder content: () -> Content) {
            self.label = label
            self.showsDivider = showsDivider
            self.content = content()
        }

        public var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .ccText(font: .cc.callout, color: .cc.foreground)
                    .frame(maxWidth: 60, alignment: .leading)

                content
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.all, 16)
            .overlay(alignment: .bottom) {
                if showsDivider { ThinLine() }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 通用编辑视图布局
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public extension CCDesigin {
    struct CCEditLayout<Content: View, ActionContent: View>: View {
        let title: String
        let content: Content
        let actionContent: ActionContent
        let backgroundColor: Color

        public init(title: String,
             backgroundColor: Color = .cc.background,
             @ViewBuilder content: () -> Content,
             @ViewBuilder actionContent: () -> ActionContent)
        {
            self.title = title
            self.backgroundColor = backgroundColor
            self.content = content()
            self.actionContent = actionContent()
        }

        public var body: some View {
            ScrollView(.vertical, content: {
                VStack(alignment: .leading, spacing: 12) {
                    CCDesigin.PageHeader(title: title)
                    content
                }
                Spacer().frame(height: 300)
            })
            .scrollDismissesKeyboard(.automatic)
            .scrollIndicators(.hidden)
            .background(backgroundColor)
            .overlay(alignment: .bottom) {
                actionContent
                    .padding(.all, 24)
            }
        }
    }
}
