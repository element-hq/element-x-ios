//
//  TextRoomTimelineItem.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

private var dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .short
    return dateFormatter
}()

enum RoomTimelineItem: Identifiable, Equatable {
    case text(id: String, senderDisplayName: String, text: String, originServerTs: Date, shouldShowSenderDetails: Bool)
    case sectionTitle(id: String, text: String)
    
    var id: String {
        switch self {
        case .text(let id, _, _, _, _):
            return id
        case .sectionTitle(let id, _):
            return id
        }
    }
}

extension RoomTimelineItem: View {
    var body: some View {
        switch self {
        case .text(let id, let senderDisplayName, let text, let originServerTs, let shouldShowSenderDetails):
            VStack(alignment: .leading) {
                if shouldShowSenderDetails {
                    HStack {
                        Text(senderDisplayName)
                            .font(.footnote)
                            .bold()
                        Spacer()
                        Text(dateFormatter.string(from: originServerTs))
                            .font(.footnote)
                    }
                    Divider()
                    Spacer()
                }
                Text(text)
            }
            .listRowSeparator(.hidden)
            .id(id)
        case .sectionTitle(let id, let text):
            LabelledDivider(label: text)
                .id(id)
        }
    }
}

struct LabelledDivider: View {

    let label: String
    let color: Color

    init(label: String, color: Color = .gray) {
        self.label = label
        self.color = color
    }

    var body: some View {
        HStack {
            line
            Text(label)
                .foregroundColor(color)
                .fixedSize()
            line
        }
    }

    var line: some View {
        VStack { Divider().background(color) }
    }
}
