//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct CountryPickerScreen: View {
    let selectedCountry: Country
    let onSelect: (Country) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""

    private var filteredCountries: [Country] {
        let sorted = Country.all.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sorted }

        let lower = query.lowercased()
        let digits = query.filter(\.isNumber)
        return sorted.filter { country in
            if country.name.lowercased().contains(lower) { return true }
            if country.isoCode.lowercased().contains(lower) { return true }
            if !digits.isEmpty, country.dialCode.hasPrefix(digits) { return true }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    onSelect(country)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.title2)
                        Text(country.name)
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textPrimary)
                        Spacer()
                        Text("+\(country.dialCode)")
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                        if country == selectedCountry {
                            CompoundIcon(\.check)
                                .foregroundStyle(.compound.iconAccentTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .listStyle(.plain)
            .searchable(text: $searchQuery, prompt: Text("Search country or code"))
            .navigationTitle("Select country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.actionCancel) { dismiss() }
                }
            }
        }
    }
}

struct CountryPickerScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        CountryPickerScreen(selectedCountry: .fallback, onSelect: { _ in })
    }
}
