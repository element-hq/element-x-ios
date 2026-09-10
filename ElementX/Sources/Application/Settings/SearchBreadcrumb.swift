//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// An entry in the search screen's history, shown when the user hasn't typed a query yet.
nonisolated enum SearchBreadcrumb: Codable, Hashable {
    /// A query the user searched for.
    case query(String)
    /// A room the user opened from the search results.
    case room(roomID: String)
}
