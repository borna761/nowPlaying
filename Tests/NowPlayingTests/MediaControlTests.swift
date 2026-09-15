import XCTest
@testable import NowPlaying

final class MediaControlTests: XCTestCase {
    func testDefaultStateIsNotPlaying() {
        let mediaControl = MediaControl()

        XCTAssertEqual(mediaControl.title, "Not playing")
        XCTAssertEqual(mediaControl.artist, "")
        XCTAssertEqual(mediaControl.album, "")
        XCTAssertFalse(mediaControl.isPlaying)
    }
}
