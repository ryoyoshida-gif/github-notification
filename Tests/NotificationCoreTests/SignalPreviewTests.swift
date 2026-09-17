import XCTest
@testable import NotificationCore

final class SignalPreviewTests: XCTestCase {
    func testHidesBotMetadataWithoutDiscardingVisibleText() {
        XCTAssertEqual(SignalPreview.text("<!-- bot marker -->\n## Deploy ready\n[Preview](https://example.com)"), "Deploy ready · Preview")
        XCTAssertEqual(SignalPreview.text("[vc]: #encoded-payload\nDeployment failed"), "Deployment failed")
        XCTAssertEqual(SignalPreview.text("<!-- truncated metadata"), "")
    }

    func testKeepsSeverityAndCodeMeaningInReview() {
        let source = "**<sub>![P1 Badge](https://example.com/p1)</sub> Fix redirect**\nUse `origin` &amp; keep the cookie."
        XCTAssertEqual(SignalPreview.text(source), "P1 Badge Fix redirect · Use origin & keep the cookie.")
    }

    func testGroupsCommentsReviewsAndFileLinksByPRNotTitle() {
        func signal(_ url: String) -> Signal {
            Signal(id: url, kind: .comment, repository: "org/repo", title: "Same title", actor: "other", excerpt: "body", url: url, date: Date())
        }
        let first = signal("https://github.com/org/repo/pull/12#issuecomment-1")
        XCTAssertEqual(first.threadKey, signal("https://github.com/org/repo/pull/12/files?diff=split#discussion_r2").threadKey)
        XCTAssertEqual(first.threadKey, signal("https://github.com/org/repo/pull/12#pullrequestreview-3").threadKey)
        XCTAssertNotEqual(first.threadKey, signal("https://github.com/org/repo/pull/13").threadKey)
        XCTAssertNotEqual(first.threadKey, signal("https://github.com/org/other/pull/12").threadKey)
    }
}
