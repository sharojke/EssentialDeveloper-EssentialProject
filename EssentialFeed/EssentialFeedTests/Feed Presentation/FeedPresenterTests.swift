import EssentialFeed
import XCTest

private final class ViewSpy: FeedLoadingView, FeedView, FeedErrorView {
    enum Message: Hashable {
        case displayError(message: String?)
        case displayLoading(isLoading: Bool)
        case displayFeed([FeedImage])
    }
    
    private(set) var messages = Set<Message>()
    
    func display(_ viewModel: FeedLoadingViewModel) {
        messages.insert(.displayLoading(isLoading: viewModel.isLoading))
    }
    
    func display(_ viewModel: FeedErrorViewModel) {
        messages.insert(.displayError(message: viewModel.message))
    }
    
    func display(_ viewModel: FeedViewModel) {
        messages.insert(.displayFeed(viewModel.feed))
    }
}

final class FeedPresenterTests: XCTestCase {
    func test_title_isLocalized() {
        XCTAssertEqual(
            FeedPresenter.title,
            localized("GENERIC_CONNECTION_ERROR")
        )
    }
    
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(
            view.messages.isEmpty,
            "Expected no view messages on initialization"
        )
    }
    
    func test_didStartLoadingFeed_displaysNoErrorMessageAndStartsLoading() {
        let (sut, view) = makeSUT()
        
        sut.didStartLoadingFeed()
        
        XCTAssertEqual(
            view.messages,
            [
                .displayError(message: nil),
                .displayLoading(isLoading: true)
            ]
        )
    }
    
    func test_didFinishLoadingFeed_displaysFeedAndStopsLoading() {
        let (sut, view) = makeSUT()
        let feed = uniqueImageFeed().models
        
        sut.didFinishLoadingFeed(with: feed)
        
        XCTAssertEqual(
            view.messages,
            [
                .displayFeed(feed),
                .displayLoading(isLoading: false)
            ]
        )
    }
    
    func test_didFinishLoadingFeed_displaysLocalizedErrorMessageAndStopLoading() {
        let (sut, view) = makeSUT()
        
        sut.didFinishLoadingFeed(with: anyNSError())
        
        XCTAssertEqual(
            view.messages,
            [
                .displayError(message: localized("GENERIC_CONNECTION_ERROR")),
                .displayLoading(isLoading: false)
            ]
        )
    }
}

// MARK: - Helpers

private extension FeedPresenterTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedPresenter(
            loadingView: view,
            feedView: view,
            errorView: view
        )
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    func localized(
        _ key: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        let table = "Feed"
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
