// SpaceFlightNewsUITests/SpaceFlightNewsUITests.swift
// App-level performance test — measures cold launch time.

import XCTest

final class SpaceFlightNewsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Measures how long the app takes to reach the first frame after launch.
    /// Xcode runs this 5 times and reports average + standard deviation.
    @MainActor
    func test_launchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
