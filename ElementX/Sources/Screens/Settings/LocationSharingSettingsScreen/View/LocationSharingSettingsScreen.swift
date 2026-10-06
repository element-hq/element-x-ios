//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LocationSharingSettingsScreen: View {
    static let measurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        return formatter
    }()
    
    @Bindable var context: LocationSharingSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            liveLocationSection
        }
        .compoundList()
        .navigationTitle(L10n.commonLocationSharing)
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Previews

struct LocationSharingSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingSettingsScreenViewModel(userSettings: .mock())
    
    static var previews: some View {
        ElementNavigationStack {
            LocationSharingSettingsScreen(context: viewModel.context)
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
