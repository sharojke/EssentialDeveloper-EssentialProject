import XCTest

final class FeedViewController {
    fileprivate init(loader: FeedViewControllerTests.LoaderSpy) {
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
}

// MARK: - Helpers

private extension FeedViewControllerTests {
    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}
