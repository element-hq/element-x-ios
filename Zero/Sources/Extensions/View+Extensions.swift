import SwiftUI

public extension View {
    func zeroList() -> some View {
        environment(\.defaultMinListRowHeight, 48)
            .scrollContentBackground(.hidden)
            .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
    }
}

extension TextField {
    func limitInputLength(_ length: Int, text: Binding<String>) -> some View {
        self.onChange(of: text.wrappedValue) { _, newValue in
            if newValue.count > length {
                text.wrappedValue = String(newValue.prefix(length))
            }
        }
    }
}
