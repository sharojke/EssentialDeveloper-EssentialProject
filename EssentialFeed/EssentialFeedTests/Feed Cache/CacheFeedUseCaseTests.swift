import XCTest

class LocalFeedLoader {
    init(store: FeedStore) {}
}

class FeedStore {
    let deleteCachedFeedCallCount = 0
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
