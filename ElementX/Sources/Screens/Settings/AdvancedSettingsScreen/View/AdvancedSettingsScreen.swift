//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AdvancedSettingsScreen: View {
    static let measurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        return formatter
    }()
    
    @Bindable var context: AdvancedSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: L10n.commonAppearance),
                        kind: .picker(selection: $context.appAppearance,
                                      items: AppAppearance.allCases.map { (title: $0.name, tag: $0) }))
                
                ListRow(label: .plain(title: L10n.actionViewSource,
                                      description: L10n.screenAdvancedSettingsViewSourceDescription),
                        kind: .toggle($context.viewSourceEnabled))
                
                ListRow(label: .plain(title: L10n.screenAdvancedSettingsSharePresence,
                                      description: L10n.screenAdvancedSettingsSharePresenceDescription),
                        kind: .toggle($context.sharePresence))
                
                ListRow(label: .plain(title: L10n.screenAdvancedSettingsMediaCompressionTitle,
                                      description: L10n.screenAdvancedSettingsMediaCompressionDescription),
                        kind: .toggle($context.optimizeMediaUploads))
                    .onChange(of: context.optimizeMediaUploads) {
                        context.send(viewAction: .optimizeMediaUploadsChanged)
                    }
            }
            
            moderationAndSafetySection
            timelineMediaSection
            if context.liveLocationSharingEnabled {
                liveLocationSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonAdvancedSettings)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var moderationAndSafetySection: some View {
        let binding = Binding(get: {
            context.viewState.hideInviteAvatars
        }, set: { newValue in
            context.send(viewAction: .updateHideInviteAvatars(newValue))
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenAdvancedSettingsHideInviteAvatarsToggleTitle),
                    details: context.viewState.isWaitingHideInviteAvatars ? .isWaiting(true) : nil,
                    kind: .toggle(binding))
                .disabled(context.viewState.isWaitingHideInviteAvatars)
        } header: {
            Text(L10n.screenAdvancedSettingsModerationAndSafetySectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    @ViewBuilder
    private var timelineMediaSection: some View {
        let binding = Binding(get: {
            context.viewState.timelineMediaVisibility
        }, set: { newValue in
            context.send(viewAction: .updateTimelineMediaVisibility(newValue))
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenAdvancedSettingsShowMediaTimelineTitle),
                    details: .isWaiting(context.viewState.isWaitingTimelineMediaVisibility),
                    kind: .inlinePicker(selection: binding,
                                        items: TimelineMediaVisibility.items))
                .disabled(context.viewState.isWaitingTimelineMediaVisibility)
        } header: {
            Text(L10n.screenAdvancedSettingsShowMediaTimelineTitle)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenAdvancedSettingsShowMediaTimelineSubtitle)
                .compoundListSectionFooter()
        }
    }
    
    @ViewBuilder
    private var liveLocationSection: some View {
        let binding = Binding(get: {
            Double(context.liveLocationMinimumDistanceUpdate)
        }, set: { newValue in
            context.liveLocationMinimumDistanceUpdate = Int(newValue)
        })
        
        Section {
            ListRow(kind: .custom {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L10n.screenAdvancedSettingsLiveLocationUpdateDistance(context.liveLocationMinimumDistanceUpdate))
                        .font(.compound.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                        // The internal hidden label of the slider will read voice over
                        .accessibilityHidden(true)
                    Slider(value: binding, in: 1...100) {
                        Text(L10n.screenAdvancedSettingsLiveLocationUpdateDistance(context.liveLocationMinimumDistanceUpdate))
                    } minimumValueLabel: {
                        Text(Self.measurementFormatter.string(from: .init(value: 1,
                                                                          unit: UnitLength.meters)))
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                            .padding(.trailing, 15)
                    } maximumValueLabel: {
                        Text(Self.measurementFormatter.string(from: .init(value: 100,
                                                                          unit: UnitLength.meters)))
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                            .padding(.leading, 15)
                    }
                    .tint(.compound.iconAccentPrimary)
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, ListRowPadding.vertical)
            })
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.screenAdvancedSettingsLiveLocationSectionTitle)
                    .compoundListSectionHeader()
                Text(L10n.screenAdvancedSettingsLiveLocationSectionDescription)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
            }
        } footer: {
            Text(context.viewState.liveLocationUpdateFooterAttributedString)
                .compoundListSectionFooter()
        }
    }
}

private extension AppAppearance {
    var name: String {
        switch self {
        case .system:
            return L10n.commonSystem
        case .light:
            return L10n.commonLight
        case .dark:
            return L10n.commonDark
        }
    }
}

// MARK: - Previews

struct AdvancedSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.liveLocationSharingEnabled = true
        return AdvancedSettingsScreenViewModel(advancedSettings: appSettings,
                                               analytics: ServiceLocator.shared.analytics,
                                               clientProxy: ClientProxyMock(.init()),
                                               userIndicatorController: UserIndicatorControllerMock())
    }()
    
    static var previews: some View {
        ElementNavigationStack {
            AdvancedSettingsScreen(context: viewModel.context)
        }
    }
}

private extension TimelineMediaVisibility {
    static var items: [(title: String, tag: TimelineMediaVisibility)] {
        [(title: L10n.screenAdvancedSettingsShowMediaTimelineAlwaysHide, tag: .never),
         (title: L10n.screenAdvancedSettingsShowMediaTimelinePrivateRooms, tag: .privateOnly),
         (title: L10n.screenAdvancedSettingsShowMediaTimelineAlwaysShow, tag: .always)]
    }
}
