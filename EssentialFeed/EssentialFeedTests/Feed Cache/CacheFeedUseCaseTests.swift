import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        
        sut.save([uniqueItem1, uniqueItem2])
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        let deletionError = anyNSError()
        
        sut.save([uniqueItem1, uniqueItem2])
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
}

// MARK: - Helpers

private extension CacheFeedUseCaseTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    func uniqueItem() -> FeedItem {
        return FeedItem(
            id: UUID(),
            imageURL: anyURL()
        )
    }
    
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

// swiftlint:enable force_unwrapping
