//
//  TimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 30/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

import Introspect

struct TimelineView: View {
    
    @State private var bottomVisiblePublisher = PassthroughSubject<Bool, Never>()
    @State private var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    @State private var scollToBottomButtonVisible = false
    
    @ObservedObject var context: RoomScreenViewModel.Context
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TimelineItemList(context: context, bottomVisiblePublisher: bottomVisiblePublisher, scrollToBottomPublisher: scrollToBottomPublisher)
            scrollToBottomButton
        }
    }
    
    @ViewBuilder
    private var scrollToBottomButton: some View {
        Button(action: {
            scrollToBottomPublisher.send(())
        }, label: {
            Image(uiImage: Asset.Images.timelineScrollToBottom.image)
                .shadow(radius: 4.0)
                .padding()
        })
        .onReceive(bottomVisiblePublisher, perform: { visible in
            scollToBottomButtonVisible = !visible
        })
        .opacity(scollToBottomButtonVisible ? 1.0 : 0.0)
        .animation(.default, value: scollToBottomButtonVisible)
    }
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            roomName: nil)
        
        TimelineView(context: viewModel.context)
    }
}
