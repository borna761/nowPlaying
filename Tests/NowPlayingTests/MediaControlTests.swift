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

    func testCandidatePathsIncludeUserLocalHomebrewPrefixes() {
        let paths = MediaControl.candidatePaths(home: "/Users/someone")

        XCTAssertTrue(paths.contains("/opt/homebrew/bin/media-control"))
        XCTAssertTrue(paths.contains("/usr/local/bin/media-control"))
        XCTAssertTrue(paths.contains("/Users/someone/homebrew/bin/media-control"))
        XCTAssertTrue(paths.contains("/Users/someone/.homebrew/bin/media-control"))
    }

    func testResolvePathReturnsFirstExistingCandidate() {
        let found = MediaControl.resolvePath(
            home: "/Users/someone",
            fileExists: { $0 == "/Users/someone/homebrew/bin/media-control" },
            shellLookup: { nil }
        )

        XCTAssertEqual(found, "/Users/someone/homebrew/bin/media-control")
    }

    func testResolvePathFallsBackToLoginShellLookup() {
        let found = MediaControl.resolvePath(
            home: "/Users/someone",
            fileExists: { $0 == "/custom/prefix/bin/media-control" },
            shellLookup: { "/custom/prefix/bin/media-control" }
        )

        XCTAssertEqual(found, "/custom/prefix/bin/media-control")
    }
}
