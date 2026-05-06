import XCTest

final class AppLaunchTests: XCTestCase {
    func test_appLaunches_andShowsRootTitle() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Questlog"].waitForExistence(timeout: 5))
    }
}
