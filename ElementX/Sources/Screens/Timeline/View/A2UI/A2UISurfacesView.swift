//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// What the node views of one surface need: the live state to report edits to, and the action callback.
struct A2UIRenderContext {
    let surfaces: A2UIMessageSurfaces
    let surfaceID: String
    let onAction: (A2UINodeKey) -> Void
    
    var isSendingAction: Bool {
        surfaces.isSendingAction
    }
    
    func setInputValue(_ value: JSONValue, for key: A2UINodeKey, path: String?) {
        surfaces.setInputValue(value, surfaceID: surfaceID, key: key, path: path)
    }
}

/// Renders the surfaces of one A2UI message as native controls.
///
/// The view walks the resolved ``A2UIRenderNode`` tree of each surface and maps every component of
/// the basic catalog onto Compound. Edits go straight to the surfaces, button presses to `onAction`.
struct A2UISurfacesView: View {
    let surfaces: A2UIMessageSurfaces
    let onAction: (_ surfaceID: String, _ key: A2UINodeKey) -> Void
    
    var body: some View {
        let renderSurfaces = surfaces.renderSurfaces
        
        VStack(alignment: .leading, spacing: 12) {
            if renderSurfaces.isEmpty {
                A2UINoticeText(UntranslatedL10n.screenRoomA2uiNoContent)
            }
            
            ForEach(renderSurfaces) { surface in
                if let root = surface.root {
                    A2UINodeView(node: root, context: .init(surfaces: surfaces, surfaceID: surface.surfaceID) { key in
                        onAction(surface.surfaceID, key)
                    })
                } else {
                    A2UINoticeText(UntranslatedL10n.screenRoomA2uiWaitingForContent)
                }
            }
            
            if let sendFailureMessage = surfaces.sendFailureMessage {
                Text(sendFailureMessage)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textCriticalPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct A2UINodeView: View {
    let node: A2UIRenderNode
    let context: A2UIRenderContext
    /// Inside a button only inline content makes sense, so text takes the button's style.
    var isInline = false
    
    var body: some View {
        switch node.kind {
        case .text(let text, let variant):
            A2UITextView(text: text, variant: isInline ? nil : variant)
        case .image(let image):
            A2UIImageView(image: image)
        case .video(let video):
            A2UIVideoView(video: video)
        case .icon(let icon):
            A2UIIconView(icon: icon)
        case .container(let container):
            A2UIContainerView(container: container, context: context)
        case .card(let child):
            A2UICardView(child: child, context: context)
        case .tabs(let tabs):
            A2UITabsView(tabs: tabs, context: context)
        case .divider:
            Divider()
        case .button(let child, let variant, let isEnabled):
            A2UIButtonView(key: node.key, child: child, variant: variant, isEnabled: isEnabled, context: context)
        case .textField(let textField):
            A2UITextFieldView(textField: textField) { setValue($0, path: textField.path) }
        case .checkBox(let checkBox):
            A2UICheckBoxView(checkBox: checkBox) { setValue($0, path: checkBox.path) }
        case .choicePicker(let picker):
            A2UIChoicePickerView(picker: picker) { setValue($0, path: picker.path) }
        case .slider(let slider):
            A2UISliderView(slider: slider) { setValue($0, path: slider.path) }
        case .dateTimeInput(let input):
            A2UIDateTimeInputView(input: input) { setValue($0, path: input.path) }
        case .unsupported(let type):
            A2UINoticeText(UntranslatedL10n.screenRoomA2uiUnsupportedComponent(type))
        }
    }
    
    private func setValue(_ value: JSONValue, path: String?) {
        context.setInputValue(value, for: node.key, path: path)
    }
}

struct A2UINoticeText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.compound.bodySM)
            .foregroundStyle(.compound.textSecondary)
    }
}

struct A2UITextView: View {
    let text: String
    /// `nil` for inline text, which takes the style of its container.
    let variant: A2UITextVariant?
    
    var body: some View {
        if let variant {
            Text(text)
                .font(font(for: variant))
                .foregroundStyle(variant == .caption ? .compound.textSecondary : .compound.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(text)
        }
    }
    
    private func font(for variant: A2UITextVariant) -> Font {
        switch variant {
        case .h1: .compound.headingLGBold
        case .h2: .compound.headingMDBold
        case .h3: .compound.headingSMSemibold
        case .h4, .h5: .compound.bodyLGSemibold
        case .caption: .compound.bodySM
        case .body: .compound.bodyLG
        }
    }
}

struct A2UIContainerView: View {
    let container: A2UIContainer
    let context: A2UIRenderContext
    
    var body: some View {
        switch container.axis {
        case .horizontal:
            // Rows wrap: a bubble is too narrow to squeeze several children onto one line.
            A2UIFlowLayout(justify: container.justify, align: container.align) {
                ForEach(container.children) { child in
                    A2UINodeView(node: child, context: context)
                        .a2uiWeight(child.weight)
                }
            }
        case .vertical:
            // Distribution only applies along a row: a column in a bubble has no spare height to distribute.
            VStack(alignment: horizontalAlignment, spacing: 8) {
                ForEach(container.children) { child in
                    A2UINodeView(node: child, context: context)
                        .frame(maxWidth: container.align == .stretch ? .infinity : nil, alignment: .leading)
                }
            }
        }
    }
    
    private var horizontalAlignment: HorizontalAlignment {
        switch container.align {
        case .start, .stretch: .leading
        case .center: .center
        case .end: .trailing
        }
    }
}

struct A2UICardView: View {
    let child: A2UIRenderNode?
    let context: A2UIRenderContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let child {
                A2UINodeView(node: child, context: context)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.compound.bgCanvasDefault, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.compound.borderDisabled))
    }
}

struct A2UITabsView: View {
    let tabs: [A2UITab]
    let context: A2UIRenderContext
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $selectedIndex) {
                ForEach(tabs.indices, id: \.self) { index in
                    Text(tabs[index].title).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            if tabs.indices.contains(selectedIndex), let child = tabs[selectedIndex].child {
                A2UINodeView(node: child, context: context)
            }
        }
    }
}

struct A2UIButtonView: View {
    let key: A2UINodeKey
    let child: A2UIRenderNode?
    let variant: A2UIButtonVariant
    let isEnabled: Bool
    let context: A2UIRenderContext
    
    var body: some View {
        styled(Button {
            context.onAction(key)
        } label: {
            if let child {
                A2UINodeView(node: child, context: context, isInline: true)
            }
        })
        .disabled(!isEnabled || context.isSendingAction)
    }
    
    @ViewBuilder
    private func styled(_ button: some View) -> some View {
        switch variant {
        case .primary:
            button.buttonStyle(.compound(.primary, size: .medium))
        case .default:
            button.buttonStyle(.compound(.secondary, size: .medium))
        case .borderless:
            button.buttonStyle(.compound(.tertiary, size: .medium))
        }
    }
}
