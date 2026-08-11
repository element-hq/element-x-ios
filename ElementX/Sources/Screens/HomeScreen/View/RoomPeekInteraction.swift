//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Drives a room cell's context menu and peek preview through UIKit's
/// `UIContextMenuInteraction` instead of SwiftUI's `.contextMenu`: SwiftUI
/// never delivers taps to its preview, and opening the peeked room on tap
/// needs the interaction's preview-commit callback. Overlay this on the cell;
/// it owns all of the cell's touch handling (tap, double tap, long press).
struct RoomPeekInteraction: UIViewRepresentable {
    let room: HomeScreenRoom
    let supportsMultipleWindows: Bool
    let reportRoomEnabled: Bool
    let viewModelBuilder: ((String) async -> TimelineViewModelProtocol?)?
    let action: (HomeScreenViewAction) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        view.addInteraction(UIContextMenuInteraction(delegate: context.coordinator))

        // Mirror the cell's previous gestures: a plain tap selects, a double
        // tap *additionally* detaches (they ran simultaneously in SwiftUI too,
        // so the single tap stays delay-free).
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap)))

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.interaction = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(interaction: self)
    }

    final class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        var interaction: RoomPeekInteraction
        private weak var scrimView: UIView?

        init(interaction: RoomPeekInteraction) {
            self.interaction = interaction
        }

        @objc func handleSingleTap() {
            interaction.action(.selectRoom(roomIdentifier: interaction.room.id))
        }

        @objc func handleDoubleTap() {
            interaction.action(.detachRoom(roomIdentifier: interaction.room.id))
        }

        // MARK: - UIContextMenuInteractionDelegate

        func contextMenuInteraction(_ contextMenuInteraction: UIContextMenuInteraction,
                                    configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            guard let windowBounds = contextMenuInteraction.view?.window?.bounds else { return nil }
            let interaction = interaction

            return UIContextMenuConfiguration(identifier: nil) {
                let controller = UIHostingController(rootView: RoomPeekView(roomID: interaction.room.id,
                                                                            viewModelBuilder: interaction.viewModelBuilder))
                // The platter floats clear of the screen edges, so the window's
                // safe areas must not inset the content again inside it.
                controller.safeAreaRegions = []
                // Match the 16pt margins used by the rest of the screen's
                // chrome and leave the bottom ~40% for the context menu.
                controller.preferredContentSize = CGSize(width: windowBounds.width - 32,
                                                         height: windowBounds.height * 0.6)
                return controller
            } actionProvider: { [weak self] _ in
                self?.makeMenu()
            }
        }

        func contextMenuInteraction(_ contextMenuInteraction: UIContextMenuInteraction,
                                    willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                    animator: UIContextMenuInteractionCommitAnimating) {
            let interaction = interaction
            animator.addCompletion {
                interaction.action(.selectRoom(roomIdentifier: interaction.room.id))
            }
        }

        func contextMenuInteraction(_ contextMenuInteraction: UIContextMenuInteraction,
                                    willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                    animator: UIContextMenuInteractionAnimating?) {
            guard let window = contextMenuInteraction.view?.window, scrimView == nil else { return }

            // The system's menu lives in its own window above this one, so a
            // window-level scrim sits behind the preview and menu but over all
            // of the app's chrome.
            let scrim = UIView(frame: window.bounds)
            scrim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            scrim.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? .black : .white }.withAlphaComponent(0.2)
            scrim.isUserInteractionEnabled = false
            scrim.alpha = 0
            window.addSubview(scrim)
            scrimView = scrim

            let fadeIn = { scrim.alpha = 1 }
            if let animator {
                animator.addAnimations(fadeIn)
            } else {
                UIView.animate(withDuration: 0.25, animations: fadeIn)
            }
        }

        func contextMenuInteraction(_ contextMenuInteraction: UIContextMenuInteraction,
                                    willEndFor configuration: UIContextMenuConfiguration,
                                    animator: UIContextMenuInteractionAnimating?) {
            guard let scrim = scrimView else { return }

            let fadeOut = { scrim.alpha = 0 }
            if let animator {
                animator.addAnimations(fadeOut)
                animator.addCompletion { scrim.removeFromSuperview() }
            } else {
                UIView.animate(withDuration: 0.25) { fadeOut() } completion: { _ in scrim.removeFromSuperview() }
            }
        }

        // MARK: - Menu

        private func makeMenu() -> UIMenu {
            let interaction = interaction
            let room = interaction.room
            var actions = [UIMenuElement]()

            if room.badges.isDotShown {
                actions.append(UIAction(title: L10n.screenRoomlistMarkAsRead, image: .compound(\.markAsRead)) { _ in
                    interaction.action(.markRoomAsRead(roomIdentifier: room.id))
                })
            } else {
                actions.append(UIAction(title: L10n.screenRoomlistMarkAsUnread, image: .compound(\.markAsUnread)) { _ in
                    interaction.action(.markRoomAsUnread(roomIdentifier: room.id))
                })
            }

            if interaction.supportsMultipleWindows {
                actions.append(UIAction(title: "Open in new window", image: .compound(\.spotlight)) { _ in
                    interaction.action(.detachRoom(roomIdentifier: room.id))
                })
            }

            if room.isFavourite {
                actions.append(UIAction(title: L10n.commonFavourited, image: .compound(\.favouriteSolid)) { _ in
                    interaction.action(.markRoomAsFavourite(roomIdentifier: room.id, isFavourite: false))
                })
            } else {
                actions.append(UIAction(title: L10n.commonFavourite, image: .compound(\.favourite)) { _ in
                    interaction.action(.markRoomAsFavourite(roomIdentifier: room.id, isFavourite: true))
                })
            }

            actions.append(UIAction(title: L10n.commonSettings, image: .compound(\.settings)) { _ in
                interaction.action(.showRoomDetails(roomIdentifier: room.id))
            })

            if interaction.reportRoomEnabled {
                actions.append(UIAction(title: L10n.actionReportRoom, image: .compound(\.chatProblem), attributes: .destructive) { _ in
                    interaction.action(.reportRoom(roomIdentifier: room.id))
                })
            }

            actions.append(UIAction(title: L10n.actionLeaveRoom, image: .compound(\.leave), attributes: .destructive) { _ in
                interaction.action(.leaveRoom(roomIdentifier: room.id))
            })

            return UIMenu(children: actions)
        }
    }
}

private extension UIImage {
    /// Renders a Compound icon for use in a `UIMenu`, tinted by the menu.
    static func compound(_ icon: KeyPath<CompoundIcons, Image>) -> UIImage? {
        let renderer = ImageRenderer(content: Image.compound[keyPath: icon]
            .resizable()
            .frame(width: 24, height: 24))
        renderer.scale = 3
        return renderer.uiImage?.withRenderingMode(.alwaysTemplate)
    }
}
