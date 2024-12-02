import Compound
import SwiftUI

public enum InfoBoxType {
    case general
    case success
    case error
}

public struct InfoBox: View {
    let text: String
    var type: InfoBoxType = .general
    
    public var body: some View {
        let backgroundTint = if type == .success {
            Color.zero.bgAccentRest.opacity(0.1)
        } else if type == .error {
            Color.compound.bgCriticalPrimary.opacity(0.1)
        } else {
            Color.compound.textSecondary.opacity(0.1)
        }
        
        HStack {
            let tintColor = if type == .success {
                Color.zero.bgAccentRest
            } else if type == .error {
                Color.compound.bgCriticalPrimary
            } else {
                Color.compound.textSecondary
            }
            
            switch type {
            case .general:
                CompoundIcon(\.infoSolid)
                    .foregroundStyle(tintColor)
            case .success:
                CompoundIcon(\.check)
                    .foregroundStyle(tintColor)
            case .error:
                CompoundIcon(\.infoSolid)
                    .foregroundStyle(tintColor)
            }
            
            Text(text)
                .font(.zero.bodySM)
                .foregroundColor(tintColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(backgroundTint, in: RoundedRectangle(cornerRadius: 6))
        .padding(.vertical, 8)
    }
}
