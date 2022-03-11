//
//  ImageRoomTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct ImageRoomTimelineView: View {
    let timelineItem: ImageRoomTimelineItem
    var loadedImage: UIImage?
    
    var body: some View {
        if let loadedImage = loadedImage {
            Image(uiImage: loadedImage)
        } else {
            ProgressView()
        }
    }
}
