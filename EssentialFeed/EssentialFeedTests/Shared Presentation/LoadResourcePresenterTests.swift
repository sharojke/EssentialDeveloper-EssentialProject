import EssentialFeed
import XCTest

private final class ViewSpy: ResourceLoadingView, ResourceView, FeedErrorView {
    typealias ResourceViewModel = String
    
    enum Message: Hashable {
        case displayError(message: String?)
        case displayLoading(isLoading: Bool)
        case display(resourceViewModel: String)
    }
    
    private(set) var messages = Set<Message>()
    
    func display(_ viewModel: ResourceLoadingViewModel) {
        messages.insert(.displayLoading(isLoading: viewModel.isLoading))
    }
    
    func display(_ viewModel: FeedErrorViewModel) {
        messages.insert(.displayError(message: viewModel.message))
    }
    
    func display(_ viewModel: String) {
        messages.insert(.display(resourceViewModel: viewModel))
    }
}

final class LoadResourcePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(
            view.messages.isEmpty,
            "Expected no view messages on initialization"
        )
    }
    
    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, view) = makeSUT()
        
        sut.didStartLoading()
        
        XCTAssertEqual(
            view.messages,
            [
                .displayError(message: nil),
                .displayLoading(isLoading: true)
            ]
        )
    }
    
    func test_didFinishLoadingResource_displaysResourceAndStopsLoading() {
        let (sut, view) = makeSUT(mapper: { resource in
            return resource + " view model"
        })
        
        sut.didFinishLoading(with: "resource")
        
        XCTAssertEqual(
            view.messages,
            [
                .display(resourceViewModel: "resource view model"),
                .displayLoading(isLoading: false)
            ]
        )
    }
    
    func test_didFinishLoading_displaysLocalizedErrorMessageAndStopLoading() {
        let (sut, view) = makeSUT()
        
        sut.didFinishLoading(with: anyNSError())
        
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

private extension LoadResourcePresenterTests {
    typealias SUT = LoadResourcePresenter<String, ViewSpy>
    
    func makeSUT(
        mapper: @escaping SUT.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: SUT, view: ViewSpy) {
        let view = ViewSpy()
        let sut = LoadResourcePresenter(
            loadingView: view,
            resourceView: view,
            errorView: view,
            mapper: mapper
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
        let bundle = Bundle(for: SUT.self)
        let table = "Shared"
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
