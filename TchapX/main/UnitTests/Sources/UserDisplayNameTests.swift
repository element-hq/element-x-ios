/*
 * MIT License
 *
 * Copyright (c) 2024. DINUM
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
