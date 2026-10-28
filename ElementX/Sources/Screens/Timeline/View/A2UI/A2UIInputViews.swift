//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A labelled input. Compound has no free-standing SwiftUI form controls, so these are styled by hand.
struct A2UIField<Content: View>: View {
    let label: String?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label, !label.isEmpty {
                Text(label)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
            }
            content()
        }
    }
}

struct A2UITextFieldView: View {
    let textField: A2UITextField
    let onChange: (JSONValue) -> Void
    
    private var text: Binding<String> {
        Binding(get: { textField.value }, set: { onChange(.string($0)) })
    }
    
    var body: some View {
        A2UIField(label: textField.label) {
            field
                .textFieldStyle(.plain)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.compound.bgCanvasDefault, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.compound.borderInteractiveSecondary))
        }
    }
    
    @ViewBuilder
    private var field: some View {
        switch textField.variant {
        case .shortText:
            TextField("", text: text)
        case .longText:
            TextField("", text: text, axis: .vertical)
                .lineLimit(3...6)
        case .number:
            TextField("", text: text)
                .keyboardType(.decimalPad)
        case .obscured:
            SecureField("", text: text)
        }
    }
}

/// A checkbox or radio-style row.
struct A2UISelectionRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                CompoundIcon(isSelected ? \.checkCircleSolid : \.circle, size: .medium, relativeTo: .compound.bodyLG)
                    .foregroundStyle(isSelected ? .compound.iconPrimary : .compound.iconSecondary)
                Text(label)
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct A2UICheckBoxView: View {
    let checkBox: A2UICheckBox
    let onChange: (JSONValue) -> Void
    
    var body: some View {
        A2UISelectionRow(label: checkBox.label, isSelected: checkBox.value) {
            onChange(.bool(!checkBox.value))
        }
    }
}

struct A2UIChoicePickerView: View {
    let picker: A2UIChoicePicker
    let onChange: (JSONValue) -> Void
    
    var body: some View {
        A2UIField(label: picker.label) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(picker.options, id: \.value) { option in
                    A2UISelectionRow(label: option.label, isSelected: picker.value.contains(option.value)) {
                        toggle(option.value)
                    }
                }
            }
        }
    }
    
    private func toggle(_ value: String) {
        var selection = picker.value
        if picker.variant == .mutuallyExclusive {
            selection = [value]
        } else if let index = selection.firstIndex(of: value) {
            selection.remove(at: index)
        } else {
            selection.append(value)
        }
        onChange(.array(selection.map(JSONValue.string)))
    }
}

struct A2UISliderView: View {
    let slider: A2UISlider
    let onChange: (JSONValue) -> Void
    
    var body: some View {
        A2UIField(label: slider.label) {
            HStack(spacing: 12) {
                Slider(value: Binding(get: { slider.value }, set: { onChange(.number($0)) }),
                       in: slider.min...Swift.max(slider.min + 1, slider.max),
                       step: 1)
                Text(slider.value.formatted())
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}

struct A2UIDateTimeInputView: View {
    let input: A2UIDateTimeInput
    let onChange: (JSONValue) -> Void
    
    private var format: A2UIDateTimeFormat {
        .init(includesDate: input.enableDate || !input.enableTime, includesTime: input.enableTime)
    }
    
    private var components: DatePickerComponents {
        var components = DatePickerComponents()
        if format.includesDate {
            components.insert(.date)
        }
        if format.includesTime {
            components.insert(.hourAndMinute)
        }
        return components
    }
    
    var body: some View {
        A2UIField(label: input.label) {
            DatePicker("",
                       selection: Binding(get: { format.date(from: input.value) ?? .now },
                                          set: { onChange(.string(format.string(from: $0))) }),
                       displayedComponents: components)
                .labelsHidden()
        }
    }
}

/// The ISO 8601 shapes a `DateTimeInput` exchanges, matching the web's `date`, `time` and `datetime-local` inputs.
nonisolated struct A2UIDateTimeFormat {
    let includesDate: Bool
    let includesTime: Bool
    
    private var pattern: String {
        switch (includesDate, includesTime) {
        case (true, true): "yyyy-MM-dd'T'HH:mm"
        case (true, false): "yyyy-MM-dd"
        case (false, _): "HH:mm"
        }
    }
    
    func date(from string: String) -> Date? {
        formatter(pattern).date(from: string) ?? formatter(pattern + ":ss").date(from: string)
    }
    
    func string(from date: Date) -> String {
        formatter(pattern).string(from: date)
    }
    
    private func formatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = pattern
        return formatter
    }
}
