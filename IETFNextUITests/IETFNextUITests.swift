//
//  IETFNextUITests.swift
//  IETFNextUITests
//
//  Created by Tom Pusateri on 11/27/22.
//

import XCTest

final class IETFNextUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    // TEMP (Claude): verify macOS fixes. Remove after use.
    func testMacFixesTEMP() throws {
        let app = XCUIApplication()
        app.launch()
        func shot(_ name: String) {
            let a = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            a.name = name; a.lifetime = .keepAlways; add(a)
        }
        func pause(_ s: Double) { Thread.sleep(forTimeInterval: s) }
        pause(4)
        app.typeKey("g", modifierFlags: .command); pause(3)
        let cbor = app.staticTexts["cbor"].firstMatch
        if cbor.waitForExistence(timeout: 5) { cbor.click(); pause(4) }
        let docs = app.buttons["Documents"].firstMatch
        if docs.waitForExistence(timeout: 3) {
            docs.click(); pause(3); shot("documents-sheet")
            let cancel = app.buttons["Cancel"].firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 3) && cancel.isHittable, "Cancel should be visible and hittable")
            cancel.click(); pause(2)
        }
        app.typeKey("l", modifierFlags: .command); pause(3); shot("rooms")
        app.typeKey("s", modifierFlags: .command); pause(4); shot("schedule")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
