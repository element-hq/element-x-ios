//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CompoundDesignTokens
import SFSafeSymbols
import SwiftUI

/// The configuration of the details portion of a list row's trailing section.
/// This consists of the title, icon and a waiting indicator.
public struct ListRowDetails<Icon: View> {
    var title: String?
    var icon: Icon?
    var counter: Int?
    
    var isWaiting = false
    
    // MARK: - Initialisers
    
    public static func label(title: String,
                             icon: Icon,
                             counter: Int? = nil,
                             isWaiting: Bool = false) -> Self {
        ListRowDetails(title: title,
                       icon: icon,
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func label(title: String,
                             icon: KeyPath<CompoundIcons, Image>,
                             counter: Int? = nil,
                             isWaiting: Bool = false) -> Self where Icon == CompoundIcon {
        ListRowDetails(title: title,
                       icon: CompoundIcon(icon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func label(title: String,
                             systemIcon: SFSymbol,
                             counter: Int? = nil,
                             isWaiting: Bool = false) -> Self where Icon == Image {
        ListRowDetails(title: title,
                       icon: Image(systemSymbol: systemIcon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func icon(_ icon: Icon,
                            counter: Int? = nil,
                            isWaiting: Bool = false) -> Self {
        ListRowDetails(icon: icon,
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func icon(_ icon: KeyPath<CompoundIcons, Image>,
                            counter: Int? = nil,
                            isWaiting: Bool = false) -> Self where Icon == CompoundIcon {
        ListRowDetails(icon:CompoundIcon(icon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func systemIcon(_ systemIcon: SFSymbol,
                                  counter: Int? = nil,
                                  isWaiting: Bool = false) -> Self where Icon == Image {
        ListRowDetails(icon: Image(systemSymbol: systemIcon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
}

public extension ListRowDetails where Icon == Image {
    static func title(_ title: String,
                      counter: Int? = nil,
                      isWaiting: Bool = false) -> Self {
        ListRowDetails(title: title,
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    static func counter(_ counter: Int, isWaiting: Bool = false) -> Self {
        ListRowDetails(counter: counter, isWaiting: isWaiting)
    }
    
    static func isWaiting(_ isWaiting: Bool) -> Self {
        ListRowDetails(isWaiting: isWaiting)
    }
}
