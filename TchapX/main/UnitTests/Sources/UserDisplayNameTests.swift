//
//  UserDisplayNaneTests.swift
//  IntegrationTests
//
//  Created by Nicolas Buquet on 09/10/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import XCTest

@testable import TchapX_Development

final class UserDisplayNaneTests: XCTestCase {
    func testUserName() {
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:matrix.test.org").homeServerName, "matrix.test.org")
        
    }

}
