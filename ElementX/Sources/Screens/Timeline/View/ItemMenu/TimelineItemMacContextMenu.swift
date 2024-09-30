//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SFSafeSymbols
import SwiftUI

/// The contents of the context menu shown when right clicking an item in the timeline on a Mac
struct TimelineItemMacContextMenu: View {
    let item: RoomTimelineItemProtocol
    let actionProvider: TimelineItemMenuActionProvider
    let send: (TimelineItemMenuAction) -> Void
    
    var body: some View {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            if let menuActions = actionProvider.makeActions() {
                Section {
                    if !menuActions.reactions.isEmpty {
                        if #available(iOS 17.0, *) {
                            let reactions = (item as? EventBasedTimelineItemProtocol)?.properties.reactions ?? []
                            ControlGroup {
                                ForEach(menuActions.reactions, id: \.key) {
                                    ReactionToggle(reaction: $0, reactions: reactions) {
                                        send(.toggleReaction(key: $0))
                                    }
                                }
                                
                                Button { send(.react) } label: {
                                    CompoundIcon(\.reactionAdd)
                                }
                            }
                            .controlGroupStyle(.palette)
                        } else {
                            Button { send(.react) } label: {
                                TimelineItemMenuAction.react.label
                            }
                        }
                    }
                    
                    ForEach(menuActions.actions) { action in
                        Button(role: action.isDestructive ? .destructive : nil) {
                            send(action)
                        } label: {
                            action.label
                        }
                    }
                }
                
                Section {
                    ForEach(menuActions.debugActions) { action in
                        Button(role: action.isDestructive ? .destructive : nil) {
                            send(action)
                        } label: {
                            action.label
                        }
                    }
                }
            }
        }
    }
}

/// A button that acts as a toggle for reacting to a message.
private struct ReactionToggle: View {
    let reaction: TimelineItemMenuReaction
    let reactions: [AggregatedReaction]
    let action: (String) -> Void
    
    var isOn: Bool {
        reactions.contains { $0.key == reaction.key && $0.isHighlighted }
    }
    
    var body: some View {
        Button { action(reaction.key) } label: {
            Image(systemSymbol: reaction.symbol)
                .symbolVariant(isOn ? .fill : .none)
        }
    }
}
