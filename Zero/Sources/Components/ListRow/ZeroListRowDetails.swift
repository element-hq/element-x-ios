import CompoundDesignTokens
import Compound
import SFSafeSymbols
import SwiftUI

/// The configuration of the details portion of a list row's trailing section.
/// This consists of the title, icon and a waiting indicator.
public struct ZeroListRowDetails<Icon: View> {
    var title: String?
    var icon: Icon?
    var counter: Int?
    
    var isWaiting = false
    
    // MARK: - Initialisers
    
    public static func label(title: String,
                             icon: Icon,
                             counter: Int? = nil,
                             isWaiting: Bool = false) -> Self {
        ZeroListRowDetails(title: title,
                       icon: icon,
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func label(title: String,
                             icon: KeyPath<CompoundIcons, Image>,
                             counter: Int? = nil,
                             isWaiting: Bool = false) -> Self where Icon == CompoundIcon {
        ZeroListRowDetails(title: title,
                       icon: CompoundIcon(icon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func label(title: String,
                             systemIcon: SFSymbol,
                             counter: Int? = nil,
                             isWaiting: Bool = false) -> Self where Icon == Image {
        ZeroListRowDetails(title: title,
                       icon: Image(systemSymbol: systemIcon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func icon(_ icon: Icon,
                            counter: Int? = nil,
                            isWaiting: Bool = false) -> Self {
        ZeroListRowDetails(icon: icon,
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func icon(_ icon: KeyPath<CompoundIcons, Image>,
                            counter: Int? = nil,
                            isWaiting: Bool = false) -> Self where Icon == CompoundIcon {
        ZeroListRowDetails(icon:CompoundIcon(icon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    public static func systemIcon(_ systemIcon: SFSymbol,
                                  counter: Int? = nil,
                                  isWaiting: Bool = false) -> Self where Icon == Image {
        ZeroListRowDetails(icon: Image(systemSymbol: systemIcon),
                       counter: counter,
                       isWaiting: isWaiting)
    }
}

public extension ZeroListRowDetails where Icon == Image {
    static func title(_ title: String,
                      counter: Int? = nil,
                      isWaiting: Bool = false) -> Self {
        ZeroListRowDetails(title: title,
                       counter: counter,
                       isWaiting: isWaiting)
    }
    
    static func counter(_ counter: Int, isWaiting: Bool = false) -> Self {
        ZeroListRowDetails(counter: counter, isWaiting: isWaiting)
    }
    
    static func isWaiting(_ isWaiting: Bool) -> Self {
        ZeroListRowDetails(isWaiting: isWaiting)
    }
}
