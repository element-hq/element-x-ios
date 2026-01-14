//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpacesAnnouncementSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let context: SpacesScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: 44, horizontalPadding: 24) {
            content
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .padding(.top, 14) // For the drag indicator
        .presentationDragIndicator(.visible)
        .onAppear { context.send(viewAction: .featureAnnouncementAppeared) }
    }
    
    var content: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.spaceSolid, style: .defaultSolid)
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(L10n.screenSpaceAnnouncementTitle)
                        .font(.compound.headingMDBold)
                        .foregroundStyle(.compound.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(L10n.commonBeta)
                        .font(.compound.bodyXSSemibold)
                        .foregroundStyle(.compound.textInfoPrimary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.compound.bgInfoSubtle)
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.compound.borderInfoSubtle)
                        }
                }
                Text(L10n.screenSpaceAnnouncementSubtitle)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            visualListItems
            
            Text(L10n.screenSpaceAnnouncementNotice)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    var visualListItems: some View {
        VStack(spacing: 4) {
            VisualListItem(title: L10n.screenSpaceAnnouncementItem1, position: .top) {
                CompoundIcon(\.visibilityOn)
                    .foregroundStyle(.compound.iconSecondary)
                    .alignmentGuide(.top) { _ in 2 }
            }
            VisualListItem(title: L10n.screenSpaceAnnouncementItem2, position: .middle) {
                CompoundIcon(\.email)
                    .foregroundStyle(.compound.iconSecondary)
                    .alignmentGuide(.top) { _ in 2 }
            }
            VisualListItem(title: L10n.screenSpaceAnnouncementItem3, position: .middle) {
                CompoundIcon(\.search)
                    .foregroundStyle(.compound.iconSecondary)
                    .alignmentGuide(.top) { _ in 2 }
            }
            // This isn't possible until we enabled the room directory.
            // VisualListItem(title: L10n.screenSpaceAnnouncementItem4, position: .middle) {
            //     CompoundIcon(\.explore)
            //         .foregroundStyle(.compound.iconSecondary)
            //         .alignmentGuide(.top) { _ in 2 }
            // }
            VisualListItem(title: L10n.screenSpaceAnnouncementItem5, position: .bottom) {
                CompoundIcon(\.leave)
                    .foregroundStyle(.compound.iconSecondary)
                    .alignmentGuide(.top) { _ in 2 }
            }
        }
    }
    
    var buttons: some View {
        Button(L10n.actionContinue, action: dismiss.callAsFunction)
            .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct SpacesAnnouncementSheetView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = SpacesScreenViewModel(userSession: UserSessionMock(.init()),
                                                 selectedSpacePublisher: .init(nil),
                                                 appSettings: ServiceLocator.shared.settings,
                                                 userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        SpacesAnnouncementSheetView(context: viewModel.context)
    }
}
