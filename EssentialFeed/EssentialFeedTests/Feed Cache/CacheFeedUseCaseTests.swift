import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

class LocalFeedLoader {
    private let store: FeedStore
    let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(
        _ items: [FeedItem],
        completion: @escaping (Error?) -> Void
    ) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            
            if error == nil {
                store.insert(
                    items: items,
                    timestamp: currentDate(),
                    completion: completion
                )
            } else {
                completion(error)
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(
        items: [FeedItem],
        timestamp: Date = Date(),
        completion: @escaping InsertionCompletion
    ) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        
        sut.save([uniqueItem1, uniqueItem2]) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        let deletionError = anyNSError()
        
        sut.save([uniqueItem1, uniqueItem2]) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT { timestamp }
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        let items = [uniqueItem1, uniqueItem2]
        
        sut.save([uniqueItem1, uniqueItem2]) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(
            store.receivedMessages,
            [
                .deleteCachedFeed,
                .insert(items, timestamp)
            ]
        )
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        let deletionError = anyNSError()
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save([uniqueItem1, uniqueItem2]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDeletion(with: deletionError)
        wait(for: [exp], timeout: 1.0)
        
        compare(error: receivedError as? NSError, with: deletionError)
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let uniqueItem1 = uniqueItem()
        let uniqueItem2 = uniqueItem()
        let items = [uniqueItem1, uniqueItem2]
        let insertionError = anyNSError()
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDeletionSuccessfully()
        store.completeInsertion(with: insertionError)
        wait(for: [exp], timeout: 1.0)
        
        compare(error: receivedError as? NSError, with: insertionError)
    }
}

// MARK: - Helpers

private extension CacheFeedUseCaseTests {
    func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
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
