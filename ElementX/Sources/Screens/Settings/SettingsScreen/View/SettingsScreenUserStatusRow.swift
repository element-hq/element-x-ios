//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SettingsScreenUserStatusRow: View {
    enum Mode: Equatable { case pick, custom, show(UserStatus.Raw) }
    let mode: Mode
    let action: (SettingsScreenViewAction.UserStatusAction) -> Void
    
    @State private var customEmoji = "😄"
    @State private var customText = ""
    
    var body: some View {
        switch mode {
        case .pick:
            ListRow(label: .default(title: L10n.screenSettingsUserStatusPlaceholder, icon: \.reaction),
                    kind: .button { action(.pickStatus) })
        case .custom:
            ListRow(kind: .custom {
                HStack(spacing: ListRowPadding.labelIconSpacing) {
                    Button { } label: {
                        Text(customEmoji)
                            .font(.compound.headingSM)
                            .foregroundStyle(.compound.textPrimary)
                    }
                    .buttonStyle(EditEmojiButtonStyle())
                    
                    TextField(L10n.screenSettingsUserStatusCustomHint, text: $customText)
                        .textFieldStyle(.compound(.raised))
                        .padding(.vertical, 3)
                    
                    ZStack { // ZStack to stop the text field from resizing.
                        Button(L10n.actionCancel) { action(.cancel) }
                            .opacity(customText.isEmpty ? 1 : 0)
                        Button(L10n.actionSave, action: saveCustomStatus)
                            .opacity(customText.isEmpty ? 0 : 1)
                    }
                    .buttonStyle(.compound(.textLink))
                }
                .listRowBackground(Color.clear)
            })
        case .show(let status):
            ListRow(kind: .custom {
                HStack(spacing: ListRowPadding.labelIconSpacing) {
                    Button { action(.pickStatus) } label: {
                        HStack(spacing: ListRowPadding.labelIconSpacing) {
                            CompoundIcon(\.reaction)
                                .hidden()
                                .overlay {
                                    Text(String(status.emoji))
                                        .font(.compound.bodyLG)
                                        .foregroundStyle(.compound.textPrimary)
                                }
                            
                            Text(status.text)
                                .font(.compound.bodyLG)
                                .foregroundStyle(.compound.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(L10n.actionClear) { action(.set(nil)) }
                        .buttonStyle(.compound(.textLink))
                }
                .padding(ListRowPadding.insets)
            })
        }
    }
    
    private func saveCustomStatus() {
        guard let emoji = customEmoji.first else { return }
        action(.set(.init(text: customText, emoji: emoji)))
    }
    
    struct EditEmojiButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(12)
                .background {
                    ZStack {
                        Circle().fill(.compound.bgCanvasDefaultLevel1)
                        Circle().inset(by: 0.5).stroke(.compound.borderInteractiveSecondary)
                    }
                }
                .drawingGroup()
                .opacity(configuration.isPressed ? 0.6 : 1)
        }
    }
}

struct SettingsScreenUserStatusRow_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            Section {
                SettingsScreenUserStatusRow(mode: .pick) { _ in }
            }
            
            Section {
                SettingsScreenUserStatusRow(mode: .custom) { _ in }
            }
            
            Section {
                SettingsScreenUserStatusRow(mode: .show(.init(text: "Away", emoji: "🌴"))) { _ in }
            }
        }
        .compoundList()
    }
}
