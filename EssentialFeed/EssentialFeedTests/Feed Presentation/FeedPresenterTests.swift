import XCTest

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
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
}

final class FeedPresenter {
    private let loadingView: FeedLoadingView
    private let errorView: FeedErrorView
    
    init(
        loadingView: FeedLoadingView,
        errorView: FeedErrorView
    ) {
        self.loadingView = loadingView
        self.errorView = errorView
    }
    
    func didStartLoadingFeed() {
        errorView.display(.noError)
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
}

final class ViewSpy: FeedLoadingView, FeedErrorView {
    enum Message: Hashable {
        case displayError(message: String?)
        case displayLoading(isLoading: Bool)
    }
    
    private(set) var messages = Set<Message>()
    
    func display(_ viewModel: FeedLoadingViewModel) {
        messages.insert(.displayLoading(isLoading: viewModel.isLoading))
    }
    
    func display(_ viewModel: FeedErrorViewModel) {
        messages.insert(.displayError(message: viewModel.message))
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
            errorView: view
        )
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
}
