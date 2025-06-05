import SwiftUI

public extension View {
    func zeroList() -> some View {
        environment(\.defaultMinListRowHeight, 48)
            .scrollContentBackground(.hidden)
            .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
    }
    
    func zeroList(backgroundColor: Color) -> some View {
        environment(\.defaultMinListRowHeight, 48)
            .scrollContentBackground(.hidden)
            .background(backgroundColor.ignoresSafeArea())
    }
}

extension TextField {
    func limitInputLength(_ length: Int, text: Binding<String>) -> some View {
        onChange(of: text.wrappedValue) { _, newValue in
            if newValue.count > length {
                text.wrappedValue = String(newValue.prefix(length))
            }
        }
    }
}
