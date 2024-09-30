//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SFSafeSymbols
import SwiftUI

/// The view can only display a max 9 items as of right now
struct SFNumberedListView: View {
    let items: [AttributedString]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(0..<items.count, id: \.self) { index in
                Label {
                    Text(items[index])
                } icon: {
                    Image(systemSymbol: getSymbol(for: index))
                        .imageScale(.large)
                        .fontWeight(.light)
                        .foregroundColor(.compound.textPlaceholder)
                }
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodyMD)
            }
        }
    }
    
    private func getSymbol(for index: Int) -> SFSymbol {
        switch index {
        case 0:
            return ._1Circle
        case 1:
            return ._2Circle
        case 2:
            return ._3Circle
        case 3:
            return ._4Circle
        case 4:
            return ._5Circle
        case 5:
            return ._6Circle
        case 6:
            return ._7Circle
        case 7:
            return ._8Circle
        case 8:
            return ._9Circle
        default:
            return ._0Circle
        }
    }
}

struct SFNumberedListView_Previews: PreviewProvider, TestablePreview {
    static let items = {
        var results: [AttributedString] = []
        for index in 1...9 {
            results.append(AttributedString("Item \(index)"))
        }
        return results
    }()
    
    static var previews: some View {
        SFNumberedListView(items: items)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
