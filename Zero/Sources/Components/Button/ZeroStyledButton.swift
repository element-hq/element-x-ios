import Compound
import SwiftUI

public struct ZeroStyledButton: View {
    let buttonText: String
    let buttonImageAsset: ImageAsset
    let action: () -> Void
    
    var enabled: Bool = true
    
    public var body: some View {
        if enabled {
            Button(action: action) {
                Image(asset: buttonImageAsset)
            }
        } else {
            Text(buttonText)
                .font(.compound.bodyLGSemibold)
                .foregroundStyle(.compound.textDisabled)
        }
    }
}
