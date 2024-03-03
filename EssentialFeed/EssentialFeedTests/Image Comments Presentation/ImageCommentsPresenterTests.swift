import EssentialFeed
import XCTest

final class ImageCommentsPresenterTests: XCTestCase {
    func test_title_isLocalized() {
        XCTAssertEqual(
            ImageCommentsPresenter.title,
            localized("IMAGE_COMMENTS_VIEW_TITLE")
        )
    }
    
    func test_map_createsViewModel() {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let locale = Locale(identifier: "en_US_POSIX")
        
        let comments = [
            ImageComment(
                id: UUID(),
                message: "a message 1",
                createdAt: now.adding(minutes: -20),
                username: "a username 1"
            ),
            ImageComment(
                id: UUID(),
                message: "a message 2",
                createdAt: now.adding(days: -5),
                username: "a username 2"
            )
        ]
        
        let viewModel = ImageCommentsPresenter.map(
            comments,
            currentDate: now,
            calendar: calendar,
            locale: locale
        )
        
        XCTAssertEqual(viewModel.comments, [
            ImageCommentViewModel(
                message: "a message 1",
                date: "20 minutes ago",
                username: "a username 1"
            ),
            ImageCommentViewModel(
                message: "a message 2",
                date: "5 days ago",
                username: "a username 2"
            )
        ])
    }
}

// MARK: - Helpers

private extension ImageCommentsPresenterTests {
    func localized(
        _ key: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let table = "ImageComments"
        let bundle = Bundle(for: FeedPresenter.self)
        let value = bundle.localizedString(
            forKey: key,
            value: nil,
            table: table
        )
        
        if value == key {
            XCTFail(
                "Missing localized string for key: \(key) in table: \(table)",
                file: file,
                line: line
            )
        }
        
        return value
    }
}
