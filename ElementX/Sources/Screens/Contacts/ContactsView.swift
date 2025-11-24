//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ContactsView: View {
    private let contacts = ["Алия", "Бекзат", "Диана", "Ержан", "Сауле"]

    var body: some View {
        NavigationStack {
            List(contacts, id: \.self) { name in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Text(String(name.prefix(1))).font(.headline))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.headline)
                        Text("Онлайн")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Контакты")
        }
    }
}

#Preview {
    ContactsView()
}
