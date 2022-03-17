//
//  TimelineItemFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

struct RoomTimelineItemFactory {
    private let mediaProvider: MediaProviderProtocol
    
    init(mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
    }
    
    func buildTimelineItemFor(_ roomMessage: RoomMessageProtocol, showSenderDetails: Bool) -> RoomTimelineItemProtocol {
        switch roomMessage {
        case let message as TextRoomMessage:
            return TextRoomTimelineItem(id: message.id,
                                        text: message.content,
                                        timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                        shouldShowSenderDetails: showSenderDetails,
                                        sender: message.sender)
        case let message as ImageRoomMessage:
            var image: UIImage?
            
            if let url = message.url {
                if mediaProvider.hasImageCachedForURL(url) {
                    mediaProvider.loadImageFromURL(url, { result in
                        if case let .success(cachedImage) = result {
                            image = cachedImage
                        }
                    })
                }
            }
            
            return ImageRoomTimelineItem(id: message.id,
                                         text: message.content,
                                         timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                         shouldShowSenderDetails: showSenderDetails,
                                         sender: message.sender,
                                         url: message.url,
                                         image: image)
        default:
            fatalError("Unknown room message.")
        }
    }
}
