//
//  UserDisplayNameTests.swift
//  IntegrationTests
//
//  Created by Nicolas Buquet on 09/10/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import XCTest

@testable import TchapX_Development

final class UserDisplayNameTests: XCTestCase {
    func testUserName() {
        XCTAssertEqual(UserDisplayName("Jean Martin [Modernisation]").userName, "Jean Martin")
        XCTAssertEqual(UserDisplayName("Jean Martin [Modernisation]").userDomain, "Modernisation")
        XCTAssertEqual(UserDisplayName("Jean Martin {Modernisation]").userName, "Jean Martin {Modernisation]")
        XCTAssertEqual(UserDisplayName("Jean Martin {Modernisation]").userDomain, "")
    }
}
