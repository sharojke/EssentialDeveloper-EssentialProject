import XCTest

final class FeedPresenter {
    init(view: Any) {
    }
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(
            view.messages.isEmpty,
            "Expected no view messages on initialization"
        )
    }
}

// MARK: - Helpers

private extension FeedPresenterTests {
    final class ViewSpy {
        let messages = [Any]()
    }
    
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedPresenter(view: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
}
