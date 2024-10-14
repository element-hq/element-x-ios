//
//  MatrixIdFromStringTests.swift
//  UnitTests
//
//  Created by Nicolas Buquet on 03/10/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import XCTest

@testable import TchapX_Development

final class Tchap_MatrixIdFromStringTests: XCTestCase {
    func testSimpleHomeServerName() {
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:matrix.test.org").homeServerName, "matrix.test.org")
        XCTAssertEqual(MatrixIdFromString("@!AAAAAAA:matrix.test.org").homeServerName, "matrix.test.org")
        XCTAssertEqual(MatrixIdFromString("@!AAAAAAA-matrix.test.org").homeServerName, "")
    }
    
    func testHomeServerDisplayName() {
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:tchap.gouv.fr").homeServerDisplayName, "Tchap.gouv.fr")
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:PREFIX.tchap.gouv.fr").homeServerDisplayName, "Prefix")
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:PREFIX.post.suffix.tchap.gouv.fr").homeServerDisplayName, "Suffix")
    }
    
    func testExternalTchapServer() {
        XCTAssertTrue(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:agent.externe.tchap.gouv.fr").isExternalTchapServer)
        XCTAssertTrue(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:e.dev01.tchap.gouv.fr").isExternalTchapServer)
      
        XCTAssertFalse(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:agent-externe.tchap.gouv.fr").isExternalTchapServer)
        XCTAssertFalse(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:agent.externes.tchap.gouv.fr").isExternalTchapServer)
        XCTAssertFalse(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:e-dev01.tchap.gouv.fr").isExternalTchapServer)
    }
    
    func testUserDisplayName() {
        XCTAssertEqual(MatrixIdFromString("@jean.martin-modernisation.fr:matrix.org").userDisplayName?.displayName, "Jean Martin")
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-modernisation.fr:matrix.org").userDisplayName?.displayName, "Jean-Philippe Martin")
        XCTAssertEqual(MatrixIdFromString("@jean.martin.de-la-rampe-modernisation.gouv.fr:a.tchap.gouv.fr").userDisplayName?.displayName, "Jean Martin De-La-Rampe")
        XCTAssertEqual(MatrixIdFromString("@jean..martin..de--la--rampe-modernisation.gouv.fr:a.tchap.gouv.fr").userDisplayName?.displayName, "Jean Martin De-La-Rampe")
        XCTAssertEqual(MatrixIdFromString("@jerome.ploquin4-developpement-durable.gouv.fr:a.tchap.gouv.fr").userDisplayName?.displayName, "Jerome Ploquin4-Developpement")
        XCTAssertEqual(MatrixIdFromString("@jerome.ploquin-otherdomain.fr:agent.externe.gouv.fr").userDisplayName?.displayName, "jerome.ploquin@otherdomain.fr")
        XCTAssertEqual(MatrixIdFromString("@jean-philippe.martin-other-domain.fr:agent.externe.gouv.fr").userDisplayName?.displayName, "jean-philippe.martin-other-domain.fr")
    }
}
