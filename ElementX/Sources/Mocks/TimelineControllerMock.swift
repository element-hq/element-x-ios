//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import Combine
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

struct TimelineControllerMockConfiguration {
    var roomProxy: JoinedRoomProxyProtocol?
    var timelineKind: TimelineKind = .live
    var timelineItems: [RoomTimelineItemProtocol] = TimelineFixtures.default
    var timelineProxy: TimelineProxyProtocol?
    var timelineItemsTimestamps: [TimelineItemIdentifier: Date] = [:]
    var paginationState: TimelinePaginationState = .initial
}

@MainActor extension TimelineControllerMock {
    static var mediaGallery: TimelineControllerMock {
        TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen), timelineItems: (0..<5).reduce([]) { partialResult, _ in
            partialResult + [TimelineFixtures.separator] + TimelineFixtures.mediaChunk
        }))
    }
    
    static var emptyMediaGallery: TimelineControllerMock {
        TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen),
                                     paginationState: TimelinePaginationState(backward: .endReached, forward: .endReached)))
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    convenience init(_ configuration: TimelineControllerMockConfiguration) {
        self.init()
        
        let lastInsertedMessageID: TimelineItemIdentifier = .event(uniqueID: .init("last_message"),
                                                                   eventOrTransactionID: .eventID("last_message"))
        let roomProxy = configuration.roomProxy
        let timelineProxy = configuration.timelineProxy
        let timelineItemsTimestamps = configuration.timelineItemsTimestamps
        
        callbacks = PassthroughSubject()
        roomID = roomProxy?.id ?? "MockRoomIdentifier"
        timelineKind = configuration.timelineKind
        paginationState = configuration.paginationState
        timelineItems = configuration.timelineItems
        
        callbacks.send(.paginationState(configuration.paginationState))
        callbacks.send(.isLive(true))
        
        focusOnEventTimelineSizeClosure = { [weak self] _, _ in
            self?.callbacks.send(.isLive(false))
            return .success(())
        }
        
        focusLiveClosure = { [weak self] in
            self?.callbacks.send(.isLive(true))
        }
        
        paginateBackwardsRequestSizeReturnValue = .success(())
        paginateForwardsRequestSizeReturnValue = .success(())
        
        sendReadReceiptForClosure = { [roomProxy] itemID in
            guard let roomProxy, let eventID = itemID.eventID else { return }
            _ = await roomProxy.timeline.sendReadReceipt(for: eventID, type: .read)
        }
        
        toggleReactionToClosure = { [timelineProxy] reaction, eventOrTransactionID in
            guard let timelineProxy else { return }
            _ = await timelineProxy.toggleReaction(reaction, to: eventOrTransactionID)
        }
        
        redactClosure = { [timelineProxy] eventOrTransactionID in
            guard let timelineProxy else { return }
            _ = await timelineProxy.redact(eventOrTransactionID, reason: nil)
        }
        
        editMessageHtmlIntentionalMentionsClosure = { [weak self] _, message, _, _ in
            guard let self else { return }
            callbacks.send(.messageSentOrEdited)
            timelineItems[timelineItems.endIndex - 1] = TextRoomTimelineItem(id: lastInsertedMessageID,
                                                                             timestamp: .distantFuture,
                                                                             isOutgoing: true,
                                                                             isEditable: true,
                                                                             canBeRepliedTo: true,
                                                                             sender: .test,
                                                                             content: .init(body: message),
                                                                             properties: .init(isEdited: true))
            callbacks.send(.updatedTimelineItems(timelineItems: timelineItems, isSwitchingTimelines: false))
        }
        
        sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure = { [weak self] message, _, _, _ in
            guard let self else { return }
            callbacks.send(.messageSentOrEdited)
            timelineItems.append(TextRoomTimelineItem(id: lastInsertedMessageID,
                                                      timestamp: .distantFuture,
                                                      isOutgoing: true,
                                                      isEditable: true,
                                                      canBeRepliedTo: true,
                                                      sender: .test,
                                                      content: .init(body: message)))
            callbacks.send(.updatedTimelineItems(timelineItems: timelineItems, isSwitchingTimelines: false))
        }
        
        sendAudioUrlAudioInfoCaptionRequestHandleClosure = { [weak self, timelineProxy] url, audioInfo, caption, requestHandle in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                return await timelineProxy.sendAudio(url: url,
                                                     audioInfo: audioInfo,
                                                     caption: caption,
                                                     requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
            }
            return .success(())
        }
        
        sendFileUrlFileInfoCaptionRequestHandleClosure = { [weak self, timelineProxy] url, fileInfo, caption, requestHandle in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                return await timelineProxy.sendFile(url: url,
                                                    fileInfo: fileInfo,
                                                    caption: caption,
                                                    requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
            }
            return .success(())
        }
        
        sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure = { [weak self, timelineProxy] url, thumbnailURL, imageInfo, caption, requestHandle in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                return await timelineProxy.sendImage(url: url,
                                                     thumbnailURL: thumbnailURL,
                                                     imageInfo: imageInfo,
                                                     caption: caption,
                                                     requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
            }
            return .success(())
        }
        
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = { [weak self, timelineProxy] body, geoURI, description, zoomLevel, assetType in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                return await timelineProxy.sendLocation(body: body,
                                                        geoURI: geoURI,
                                                        description: description,
                                                        zoomLevel: zoomLevel,
                                                        assetType: assetType).mapError(TimelineControllerError.timelineProxyError)
            }
            return .success(())
        }
        
        sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure = { [weak self, timelineProxy] url, thumbnailURL, videoInfo, caption, requestHandle in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                return await timelineProxy.sendVideo(url: url,
                                                     thumbnailURL: thumbnailURL,
                                                     videoInfo: videoInfo,
                                                     caption: caption,
                                                     requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
            }
            return .success(())
        }
        
        sendVoiceMessageUrlAudioInfoWaveformInReplyToEventIDRequestHandleClosure = { [weak self, timelineProxy] url, audioInfo, waveform, inReplyToEventID, requestHandle in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                return await timelineProxy.sendVoiceMessage(url: url,
                                                            audioInfo: audioInfo,
                                                            waveform: waveform,
                                                            inReplyToEventID: inReplyToEventID,
                                                            requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
            }
            return .success(())
        }
        
        createPollQuestionAnswersMaxSelectionsPollKindClosure = { [weak self, timelineProxy] question, answers, maxSelections, pollKind in
            self?.callbacks.send(.messageSentOrEdited)
            if let timelineProxy {
                _ = await timelineProxy.createPoll(question: question, answers: answers, maxSelections: maxSelections, pollKind: pollKind)
            }
            return .success(())
        }
        
        editPollOriginalQuestionAnswersMaxSelectionsPollKindClosure = { [timelineProxy] eventID, question, answers, maxSelections, pollKind in
            if let timelineProxy {
                _ = await timelineProxy.editPoll(original: eventID, question: question, answers: answers, maxSelections: maxSelections, pollKind: pollKind)
            }
            return .success(())
        }
        
        sendPollResponsePollStartIDAnswersClosure = { [timelineProxy] pollStartID, answers in
            if let timelineProxy {
                _ = await timelineProxy.sendPollResponse(pollStartID: pollStartID, answers: answers)
            }
            return .success(())
        }
        
        endPollPollStartIDTextClosure = { [timelineProxy] pollStartID, text in
            if let timelineProxy {
                _ = await timelineProxy.endPoll(pollStartID: pollStartID, text: text)
            }
            return .success(())
        }
        
        messageEventContentForReturnValue = RoomMessageEventContentWithoutRelationSDKMock()
        debugInfoForReturnValue = .init(model: "Mock debug description", originalJSON: nil, latestEditJSON: nil)
        
        eventTimestampForClosure = { [timelineItemsTimestamps] itemID in
            timelineItemsTimestamps[itemID] ?? .now
        }
    }
    
    func update(paginationState: TimelinePaginationState) {
        self.paginationState = paginationState
        callbacks.send(.paginationState(paginationState))
    }
    
    /// Configures `paginateBackwardsRequestSizeClosure` to simulate back pagination from the given response queue,
    /// sending the appropriate `updatedTimelineItems` and `paginationState` callbacks each time.
    func setupBackPagination(responses: [[RoomTimelineItemProtocol]]) {
        var queue = responses
        paginateBackwardsRequestSizeClosure = { [weak self] _ in
            guard let self else { return .success(()) }
            
            let paginating = TimelinePaginationState(backward: .paginating, forward: .endReached)
            paginationState = paginating
            callbacks.send(.paginationState(paginating))
            
            guard !queue.isEmpty else {
                let end = TimelinePaginationState(backward: .endReached, forward: .endReached)
                paginationState = end
                callbacks.send(.paginationState(end))
                return .success(())
            }
            
            let newItems = queue.removeFirst()
            timelineItems.insert(contentsOf: newItems, at: 0)
            callbacks.send(.updatedTimelineItems(timelineItems: timelineItems, isSwitchingTimelines: false))
            
            let final = TimelinePaginationState(backward: queue.isEmpty ? .endReached : .idle, forward: .endReached)
            paginationState = final
            callbacks.send(.paginationState(final))
            
            return .success(())
        }
    }
}
