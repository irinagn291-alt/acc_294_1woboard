import XCTest
@testable import Callboard

final class ReviewLaunchTests: XCTestCase {
    func test_screenParsesReviewArgument() {
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Callboard", "-ReviewScreen", "today"]),
            "today"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Callboard", "-ReviewScreen", "log"]),
            "log"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Callboard", "-ReviewScreen", "goals"]),
            "goals"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Callboard", "-ReviewScreen", "shifts"]),
            "shifts"
        )
        XCTAssertNil(ReviewLaunch.screen(in: ["Callboard"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["Callboard", "-ReviewScreen"]))
    }
}
