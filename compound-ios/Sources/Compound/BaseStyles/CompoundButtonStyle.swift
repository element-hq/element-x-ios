//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public extension ButtonStyle where Self == CompoundButtonStyle {
    /// A button style that applies Compound design tokens to a button with various configuration options.
    /// - Parameter kind: The kind of button being shown such as primary or secondary.
    /// - Parameter size: The button size to use. Defaults to `large`.
    static func compound(_ kind: Self.Kind, size: Self.Size = .large) -> CompoundButtonStyle {
        CompoundButtonStyle(kind: kind, size: size)
    }
}

/// Default button style for standalone buttons.
public struct CompoundButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityShowButtonShapes) private var accessibilityShowButtonShapes
    
    var kind: Kind
    public enum Kind {
        /// A stroked button that uses colour to highlight important actions.
        case `super`
        /// A filled button usually representing the default action.
        case primary
        /// A stroked button usually representing alternate actions.
        case secondary
        /// A plain button with matching dimensions to ``primary`` and ``secondary``.
        case tertiary
        /// A plain button with no padding.
        case textLink
    }
    
    var size: Size
    public enum Size {
        /// A button that is prominently sized.
        case large
        /// A button that is a regular size.
        case medium
        /// A button that is a small size.
        case small
        /// A (super/primary/secondary) button that should be place within a toolbar.
        case toolbarIcon
    }
    
    private var font: Font {
        if kind == .textLink, size == .small {
            .compound.bodyMDSemibold
        } else {
            .compound.bodyLGSemibold
        }
    }
    
    private var horizontalPadding: CGFloat {
        if kind == .textLink {
            return 0
        }
        
        return switch size {
        case .large: 20
        case .medium: 20
        case .small: 16
        case .toolbarIcon: 3
        }
    }

    private var verticalPadding: CGFloat {
        if kind == .textLink {
            return 0
        }
        
        return switch size {
        case .large: 14
        case .medium: 7
        case .small: 4
        case .toolbarIcon: 3
        }
    }
    
    private var maxWidth: CGFloat? {
        if kind == .textLink {
            return nil
        }
        
        return switch size {
        case .large: .infinity
        case .medium: nil
        case .small: nil
        case .toolbarIcon: nil
        }
    }
    
    private var pressedOpacity: Double {
        colorScheme == .light ? 0.3 : 0.6
    }
    
    private var isUnderlined: Bool {
        kind == .textLink && accessibilityShowButtonShapes
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(font)
            .underline(isUnderlined)
            .multilineTextAlignment(.center)
            .foregroundColor(textColor(configuration: configuration))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: maxWidth)
            .background {
                makeBackground(configuration: configuration)
            }
            .contentShape(contentShape)
    }
    
    @ViewBuilder
    private func makeBackground(configuration: Self.Configuration) -> some View {
        switch kind {
        case .super:
            if isEnabled {
                ZStack {
                    Capsule().fill(.compound.bgCanvasDefault)
                    Capsule().fill(LinearGradient(gradient: .compound.action,
                                                  startPoint: .top, endPoint: .bottom))
                        .opacity(0.04)
                    Capsule().strokeBorder(LinearGradient(gradient: .compound.action,
                                                          startPoint: .top, endPoint: .bottom))
                }
                .compositingGroup()
                .opacity(configuration.isPressed ? pressedOpacity : 1)
            } else {
                Capsule().strokeBorder(strokeColor(configuration: configuration))
            }
        case .primary:
            Capsule().fill(fillColor(configuration: configuration))
        case .secondary:
            Capsule().strokeBorder(strokeColor(configuration: configuration))
        case .tertiary:
            EmptyView()
        case .textLink:
            EmptyView()
        }
    }

    private var contentShape: AnyShape {
        switch kind {
        case .super, .primary, .secondary, .tertiary:
            return AnyShape(Capsule())
        case .textLink:
            return AnyShape(Rectangle())
        }
    }

    private func fillColor(configuration: Self.Configuration) -> Color {
        guard isEnabled else { return .compound.bgActionPrimaryDisabled }
        if configuration.role == .destructive {
            return .compound.bgCriticalPrimary.opacity(configuration.isPressed ? pressedOpacity : 1)
        } else {
            return configuration.isPressed ? .compound.bgActionPrimaryPressed : .compound.bgActionPrimaryRest
        }
    }
    
    private func strokeColor(configuration: Self.Configuration) -> Color {
        if configuration.role == .destructive {
            return .compound.borderCriticalPrimary.opacity(configuration.isPressed ? pressedOpacity : 1)
        } else {
            return .compound.borderInteractiveSecondary.opacity(configuration.isPressed ? pressedOpacity : 1)
        }
    }
    
    private func textColor(configuration: Configuration) -> Color {
        if kind == .primary {
            return .compound.textOnSolidPrimary
        } else {
            guard isEnabled else { return .compound.textDisabled }
            let textColor: Color = configuration.role == .destructive ? .compound.textCriticalPrimary : .compound.textActionPrimary
            return textColor.opacity(configuration.isPressed ? pressedOpacity : 1)
        }
    }
}

// MARK: - Previews

public struct CompoundButtonStyle_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        ScrollView {
            states
        }
        .previewLayout(.fixed(width: 390, height: 1875))
    }
    
    @ViewBuilder
    public static var states: some View {
        Section {
            buttons(.large)
        } header: {
            Header(title: "Large")
        }
        
        Section {
            buttons(.medium)
        } header: {
            Header(title: "Medium")
        }
        
        Section {
            buttons(.small)
        } header: {
            Header(title: "Small")
        }
        
        Section {
            textLinks(.medium)
        } header: {
            Header(title: "Text Link")
        }
        
        Section {
            textLinks(.small)
        } header: {
            Header(title: "Text Link Small")
        }
        
        Section {
            startChat
                .padding(.bottom) // Only for the snapshot.
        } header: {
            Header(title: "Start chat")
        }
    }
    
    public static func buttons(_ size: CompoundButtonStyle.Size) -> some View {
        VStack {
            Button("Super") { }
                .buttonStyle(.compound(.super, size: size))
            
            Button("Disabled") { }
                .buttonStyle(.compound(.super, size: size))
                .disabled(true)
            
            Button("Primary") { }
                .buttonStyle(.compound(.primary, size: size))
            
            Button("Destructive", role: .destructive) { }
                .buttonStyle(.compound(.primary, size: size))
            
            Button("Disabled") { }
                .buttonStyle(.compound(.primary, size: size))
                .disabled(true)
            
            Button("Secondary") { }
                .buttonStyle(.compound(.secondary, size: size))
            
            Button("Destructive", role: .destructive) { }
                .buttonStyle(.compound(.secondary, size: size))
            
            Button("Disabled") { }
                .buttonStyle(.compound(.secondary, size: size))
                .disabled(true)
            
            Button("Tertiary") { }
                .buttonStyle(.compound(.tertiary, size: size))
            
            Button("Destructive", role: .destructive) { }
                .buttonStyle(.compound(.tertiary, size: size))
            
            Button("Disabled") { }
                .buttonStyle(.compound(.tertiary, size: size))
                .disabled(true)
        }
        .padding(.horizontal)
    }
    
    static func textLinks(_ size: CompoundButtonStyle.Size) -> some View {
        HStack(spacing: 20) {
            Button("Text Link") { }
                .buttonStyle(.compound(.textLink, size: size))
            
            Button("Destructive", role: .destructive) { }
                .buttonStyle(.compound(.textLink, size: size))
            
            Button("Disabled") { }
                .buttonStyle(.compound(.textLink, size: size))
                .disabled(true)
        }
        .padding(.top, 1)
    }
    
    static var startChat: some View {
        Button { } label: {
            CompoundIcon(\.plus)
        }
        .buttonStyle(.compound(.super, size: .toolbarIcon))
    }
    
    struct Header: View {
        let title: String
        
        var body: some View {
            Text(title)
                .foregroundStyle(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .top])
                .padding(.leading )
        }
    }
}
