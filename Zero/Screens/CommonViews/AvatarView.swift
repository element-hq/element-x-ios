import Kingfisher
import SwiftUI

public struct AvatarView: View {
    public enum Style {
        case large
        case medium
        case small
        case extraSmall
        case extraLarge
        case XXL
        
        var dimension: CGFloat {
            switch self {
            case .large:
                return 64
            case .medium:
                return 48
            case .small:
                return 32
            case .extraSmall:
                return 16
            case .extraLarge:
                return 120
            case .XXL:
                return 160
            }
        }
    }
    
    var radius: CGFloat
    var offset: CGFloat {
        sqrt(radius * radius / 2)
    }
    
    public let url: URL?
    let placeholder: ImageAsset?
    public let style: AvatarView.Style
    
    init(
        url: URL?,
        placeholder: ImageAsset?,
        style: AvatarView.Style
    ) {
        self.url = url
        self.placeholder = placeholder
        self.style = style
        
        radius = self.style.dimension / 2
    }
    
    public var body: some View {
        let dimensionProportion = style.dimension / 4
        
        KFAnimatedImage(url)
            .placeholder { _ in
                if let image = placeholder {
                    Image(asset: image)
                } else {
                    Color.black
                }
            }
            .startLoadingBeforeViewAppear(false)
            .aspectRatio(contentMode: .fill)
            .frame(
                width: style.dimension,
                height: style.dimension
            )
            .background(.black)
            .clipShape(Circle())
    }
}

public struct AvatarViewPreview: PreviewProvider {
    public static var previews: some View {
        AvatarView(
            url: URL(string: "https://gravatar.com/avatar/8b01c662419106d1bb45b6fc4ad669b3?s=400&d=robohash&r=x"),
            placeholder: nil,
            style: .large
        )
    }
}
