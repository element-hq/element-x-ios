import ArgumentParser
import SwiftUI

struct AppIconBanner: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A Swift command-line tool to add a banner to an app icons.")
    
    @Argument(help: "Path to the input image.")
    var path: String
        
    @Option(help: "Text for the banner.")
    var bannerText: String
        
    @MainActor
    func run() async throws {
        let currentDirectoryURL = URL(filePath: FileManager.default.currentDirectoryPath)
        let pathURL = currentDirectoryURL.appending(path: path)
        
        guard let image = NSImage(contentsOf: pathURL) else {
            throw ValidationError("Could not load the image at \(pathURL).")
        }
        
        let renderer = ImageRenderer(content: BannerImage(image: image,
                                                          text: bannerText))
        
        do {
            guard let cgImage = renderer.cgImage else {
                throw ValidationError("Couldn't generate CG image.")
            }
            
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            
            guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
                throw ValidationError("Couldn't create png data from image.")
            }
            
            try pngData.write(to: pathURL)
            print("Successfully saved the image with a banner to \(pathURL).")
        } catch {
            throw ValidationError("Failed to save the image: \(error).")
        }
    }
}

struct BannerImage: View {
    let image: NSImage
    let text: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 135, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, image.size.width * 0.1)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 30)
        }
        .frame(width: image.size.width, height: image.size.height)
    }
}
