import SwiftUI

public extension View {
    func zeroList() -> some View {
        environment(\.defaultMinListRowHeight, 48)
            .scrollContentBackground(.hidden)
            .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
    }
}
