//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeScreenPostMeowButton: View {
    let count: String
    let highlightColor: Bool
    let isEnabled: Bool
    
    @State private var counter: Int = 0
    @State private var isTouching: Bool = false
    @State private var timer: Timer? = nil
    
    private let MAX_MEOW_LIMIT = 100
    
    let onMeowTouchEnded: (Int) -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            HomeScreenPostFooterItem(icon: Asset.Images.postMeowIcon,
                                     count: count,
                                     highlightColor: highlightColor,
                                     action: {})
            .simultaneousGesture(
                DragGesture(minimumDistance: 0) // Detect touch down
                    .onChanged { _ in
                        if !isTouching, isEnabled {
                            startIncrementing()
                            isTouching = true
                        }
                    }
                    .onEnded { _ in
                        if isEnabled {
                            onMeowTouchEnded(counter)
                        }
                        stopIncrementing()
                        isTouching = false
                    }
            )
            
            if isTouching {
                Text("+\(counter)")
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.zero.bgAccentRest)
            }
        }
    }
    
    func startIncrementing() {
        stopIncrementing()
        // Start a timer that fires every 250 milliseconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            if counter < MAX_MEOW_LIMIT {
                counter += 1
            }
        }
    }
    
    func stopIncrementing() {
        // Stop the timer when touch ends
        timer?.invalidate()
        timer = nil
        counter = 0
    }
}
