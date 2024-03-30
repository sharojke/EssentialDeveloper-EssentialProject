import EssentialFeed
import XCTest

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        try? sut.save(uniqueImageFeed().models)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        try? sut.save(uniqueImageFeed().models)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT { timestamp }
        let feed = uniqueImageFeed()
        
        try? sut.save(feed.models)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [
            .deleteCachedFeed,
            .insert(feed.local, timestamp)
        ])
    }
    
    // TODO: Uncomment the tests
    
//    func test_save_failsOnDeletionError() {
//        let (sut, store) = makeSUT()
//        let deletionError = anyNSError()
//        
//        expect(sut, toCompleteWithError: deletionError) {
//            store.completeDeletion(with: deletionError)
//        }
//    }
//    
//    func test_save_failsOnInsertionError() {
//        let (sut, store) = makeSUT()
//        let insertionError = anyNSError()
//        
//        expect(sut, toCompleteWithError: insertionError) {
//            store.completeDeletionSuccessfully()
//            store.completeInsertion(with: insertionError)
//        }
//    }
//    
//    func test_save_successesOnSuccessfulCacheInsertion() {
//        let (sut, store) = makeSUT()
//        
//        expect(sut, toCompleteWithError: nil) {
//            store.completeDeletionSuccessfully()
//            store.completeInsertionSuccessfully()
//        }
//    }
}

// MARK: - Helpers

private extension CacheFeedUseCaseTests {
    func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
//    func expect(
//        _ sut: LocalFeedLoader,
//        toCompleteWithError expectedError: NSError?,
//        on action: () -> Void,
//        file: StaticString = #filePath,
//        line: UInt = #line
//    ) {
//        action()
//        
//        do {
//            try sut.save(uniqueImageFeed().models)
//        } catch {
//            compare(
//                error: error as NSError,
//                with: expectedError,
//                file: file,
//                line: line
//            )
//        }
//    }
}
