import EssentialFeed
import XCTest

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

struct FeedLoadingViewModel {
    let isLoading: Bool
}

struct FeedErrorViewModel {
    static var noError: Self {
        return Self(message: nil)
    }

    let message: String?
    
    static func error(message: String) -> Self {
        return Self(message: message)
    }
}

struct FeedViewModel {
    let feed: [FeedImage]
}

final class FeedPresenter {
    static var title: String {
        return NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't load the image feed from the server"
        )
    }
    
    private let loadingView: FeedLoadingView
    private let feedView: FeedView
    private let errorView: FeedErrorView
    
    private var feedLoadError: String {
        return NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't load the image feed from the server"
        )
    }
    
    init(
        loadingView: FeedLoadingView,
        feedView: FeedView,
        errorView: FeedErrorView
    ) {
        self.loadingView = loadingView
        self.feedView = feedView
        self.errorView = errorView
    }
    
    func didStartLoadingFeed() {
        errorView.display(.noError)
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        errorView.display(.error(message: feedLoadError))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}

final class ViewSpy: FeedLoadingView, FeedView, FeedErrorView {
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
            localized("FEED_VIEW_CONNECTION_ERROR")
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
                .displayError(message: localized("FEED_VIEW_CONNECTION_ERROR")),
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
