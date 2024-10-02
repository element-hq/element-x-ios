//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// The custom keypad shown on the App Lock screen when biometrics are disabled.
struct AppLockScreenPINKeypad: View {
    @Binding var pinCode: String
    
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

// MARK: - Previews

struct AppLockScreenPINKeypad_Previews: PreviewProvider {
    static var previews: some View {
        KeypadTestView()
    }
    
    struct KeypadTestView: View {
        @StateObject var model = PreviewModel()
        class PreviewModel: ObservableObject {
            @Published var pinCode = ""
            var output: String { pinCode.isEmpty ? "Enter code" : pinCode }
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
