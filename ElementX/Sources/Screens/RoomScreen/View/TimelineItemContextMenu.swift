//
//  TimelineItemContextMenu.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import SwiftUI

public struct TimelineItemContextMenu: View {
    
    let contextMenuActions: [TimelineItemContextMenuAction]
    let callback: (TimelineItemContextMenuAction) -> Void
    
    @ViewBuilder
    public var body: some View {
        ForEach(contextMenuActions, id: \.self) { item in
            switch item {
            case .copy:
                Button("Copy") {
                    callback(item)
                }
            case .quote:
                Button("Quote") {
                    callback(item)
                }
            }
        }
    }
}
