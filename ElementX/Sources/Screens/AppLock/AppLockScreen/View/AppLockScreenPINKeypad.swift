//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
