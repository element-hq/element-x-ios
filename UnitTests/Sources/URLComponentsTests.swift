//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct URLComponentsTests {
    @Test
    func addFragmentQueryItems() throws {
        let url = try #require(URL(string: "https://test.matrix.org"))
        var components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        
        #expect(components.fragmentQueryItems == nil)
        
        let fragmentQueryItems: [URLQueryItem] = [.init(name: "first", value: "1"), .init(name: "second", value: "2")]
        components.fragmentQueryItems = fragmentQueryItems
        
        #expect(components.url?.absoluteString == "https://test.matrix.org#?first=1&second=2")
    }
    
    @Test
    func removeFragmentQueryItem() throws {
        let url = try #require(URL(string: "https://test.matrix.org#random/data?first=1&second=2"))
        var components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
                
        #expect(components.fragmentQueryItems != nil)
        var fragmentQueryItems = try #require(components.fragmentQueryItems)
        
        fragmentQueryItems.removeAll { $0.name == "first" }
        
        components.fragmentQueryItems = fragmentQueryItems
        
        #expect(components.url?.absoluteString == "https://test.matrix.org#random/data?second=2")
    }
    
    @Test
    func appendFragmentQueryItem() throws {
        let url = try #require(URL(string: "https://test.matrix.org#/random/data?first=1&second=2"))
        var components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
                
        #expect(components.fragmentQueryItems != nil)
        var fragmentQueryItems = try #require(components.fragmentQueryItems)
        
        fragmentQueryItems.insert(.init(name: "mr in between", value: "hello"), at: 1)
        
        components.fragmentQueryItems = fragmentQueryItems
        
        #expect(components.url?.absoluteString == "https://test.matrix.org#/random/data?first=1&mr%20in%20between=hello&second=2")
    }
    
    @Test
    func changeFragmentQueryItemValue() throws {
        let url = try #require(URL(string: "https://test.matrix.org#/random/data?first=1&second=2"))
        var components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        
        #expect(components.fragmentQueryItems != nil)
        var fragmentQueryItems = try #require(components.fragmentQueryItems)
        
        fragmentQueryItems[0].value = "last"
        
        components.fragmentQueryItems = fragmentQueryItems
        
        #expect(components.url?.absoluteString == "https://test.matrix.org#/random/data?first=last&second=2")
    }
    
    @Test
    func elementCallParameters() throws {
        let url = try #require(URL(string: "https://call.element.io/room#/callName?appPrompt=true&confineToRoom=false"))
        var components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: true))
        
        components.fragmentQueryItems?.removeAll { $0.name == "appPrompt" }
        components.fragmentQueryItems?.removeAll { $0.name == "confineToRoom" }
        
        components.fragmentQueryItems?.append(.init(name: "skipLobby", value: "true"))
        
        components.fragmentQueryItems?.append(.init(name: "appPrompt", value: "false"))
        components.fragmentQueryItems?.append(.init(name: "confineToRoom", value: "true"))
        
        #expect(components.url?.absoluteString == "https://call.element.io/room#/callName?skipLobby=true&appPrompt=false&confineToRoom=true")
    }
}
