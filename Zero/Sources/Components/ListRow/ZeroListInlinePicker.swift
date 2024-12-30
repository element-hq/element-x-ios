import SwiftUI

struct ZeroListInlinePicker<SelectedValue: Hashable>: View {
    let title: String?
    @Binding var selection: SelectedValue
    let items: [(title: String, tag: SelectedValue)]
    
    var body: some View {
        ForEach(items, id: \.tag) { item in
            ZeroListRow(label: .plain(title: item.title),
                        kind: .selection(isSelected: selection == item.tag) {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true

                            withTransaction(transaction) {
                                selection = item.tag
                            }
                        })
        }
    }
}
