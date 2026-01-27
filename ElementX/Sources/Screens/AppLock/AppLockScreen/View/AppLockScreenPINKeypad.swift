//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The custom keypad shown on the App Lock screen when biometrics are disabled.
struct AppLockScreenPINKeypad: View {
    @Binding var pinCode: String
    @FocusState private var isFocused
    
    var body: some View {
        Grid(horizontalSpacing: 24, verticalSpacing: 16) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(1..<4) { column in
                        let digit = (3 * row) + column
                        Button("\(digit)") { press(digit) }
                            .accessibilityIdentifier(A11yIdentifiers.appLockScreen.numpad(digit))
                    }
                }
            }
            GridRow {
                Button("") { }.hidden()
                Button("0") { press(0) }
                    .accessibilityIdentifier(A11yIdentifiers.appLockScreen.numpad(0))
                Button(action: pressDelete) {
                    Image(systemSymbol: .deleteBackward)
                        .symbolVariant(.fill)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.compound.textPrimary, .compound.bgSubtlePrimary)
                }
                .buttonStyle(KeypadButtonStyle(isSolid: false))
            }
        }
        .buttonStyle(KeypadButtonStyle())
        .focusable()
        .focused($isFocused)
        .onKeyPress(keys: Self.supportedKeys) { keyPress in
            guard keyPress.key != .delete else {
                // Since the key press event is handled through a view update we need to update the view on the next main loop
                DispatchQueue.main.async {
                    pressDelete()
                }
                return .handled
            }
            
            guard let digit = Int(keyPress.characters) else {
                return .ignored
            }
            
            // Since the key press event is handled through a view update we need to update the view on the next main loop
            DispatchQueue.main.async {
                press(digit)
            }
            return .handled
        }
        .onAppear {
            isFocused = true
        }
    }
    
    func press(_ digit: Int) {
        guard pinCode.count < 4 else { return }
        UIDevice.current.playInputClick()
        pinCode.append("\(digit)")
    }
    
    func pressDelete() {
        guard !pinCode.isEmpty else { return }
        withElementAnimation { _ = pinCode.removeLast() }
    }
}

private struct KeypadButtonStyle: ButtonStyle {
    var isSolid = true
    
    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .fill(isSolid ? .compound.bgSubtlePrimary : .clear)
            .frame(width: 80, height: 80)
            .overlay {
                configuration.label
                    .font(.compound.headingXLBold)
                    .foregroundColor(.compound.textPrimary)
            }
            .opacity(configuration.isPressed ? 0.3 : 1.0)
    }
}

private extension AppLockScreenPINKeypad {
    static let supportedKeys: Set<KeyEquivalent> = [.init("0"),
                                                    .init("1"),
                                                    .init("2"),
                                                    .init("3"),
                                                    .init("4"),
                                                    .init("5"),
                                                    .init("6"),
                                                    .init("7"),
                                                    .init("8"),
                                                    .init("9"),
                                                    .delete]
}

// MARK: - Previews

struct AppLockScreenPINKeypad_Previews: PreviewProvider {
    static var previews: some View {
        KeypadTestView()
    }
    
    struct KeypadTestView: View {
        @StateObject var model = PreviewModel()
        class PreviewModel: ObservableObject {
            @Published var pinCode = ""
            var output: String {
                pinCode.isEmpty ? "Enter code" : pinCode
            }
        }
        
        var body: some View {
            VStack(spacing: 32) {
                Text(model.output)
                    .font(.compound.headingMD)
                    .animation(.noAnimation, value: model.pinCode)
                AppLockScreenPINKeypad(pinCode: $model.pinCode)
            }
        }
    }
}
