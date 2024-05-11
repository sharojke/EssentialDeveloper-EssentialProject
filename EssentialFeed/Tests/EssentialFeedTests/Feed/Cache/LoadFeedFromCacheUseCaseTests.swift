import EssentialFeed
import XCTest

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        expect(
            sut,
            toCompleteWithResult: .failure(error),
            on: {
                store.completeRetrieval(with: error)
            }
        )
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        expect(
            sut,
            toCompleteWithResult: .success([]),
            on: {
                store.completeRetrievalWithEmptyCache()
            }
        )
    }
    
    func test_load_deliversCachedImagesOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        
        expect(
            sut,
            toCompleteWithResult: .success(feed.models),
            on: {
                store.completeRetrieval(
                    with: feed.local,
                    timestamp: nonExpiredTimestamp
                )
            }
        )
    }
    
    func test_load_deliversNoCachedImagesOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        
        expect(
            sut,
            toCompleteWithResult: .success([]),
            on: {
                store.completeRetrieval(
                    with: feed.local,
                    timestamp: expirationTimestamp
                )
            }
        )
    }
    
    func test_load_deliversNoCachedImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        
        expect(
            sut,
            toCompleteWithResult: .success([]),
            on: {
                store.completeRetrieval(
                    with: feed.local,
                    timestamp: expiredTimestamp
                )
            }
        )
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        store.completeRetrieval(with: anyNSError())
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        store.completeRetrievalWithEmptyCache()
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        store.completeRetrieval(
            with: feed.local,
            timestamp: expirationTimestamp
        )
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
}

// MARK: - Helpers

private extension LoadFeedFromCacheUseCaseTests {
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
    
    func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithResult expectedResult: Result<[FeedImage], Error>,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()
        let receivedResult = Result { try sut.load() }
        
        switch (receivedResult, expectedResult) {
        case (.success(let receivedImages), .success(let expectedImages)):
            XCTAssertEqual(
                receivedImages,
                expectedImages,
                file: file,
                line: line
            )
            
        case (.failure(let receivedError), .failure(let expectedError)):
            compare(
                error: receivedError as NSError,
                with: expectedError as NSError,
                file: file,
                line: line
            )
            
        default:
            XCTFail(
                "Expected \(expectedResult), got \(receivedResult)",
                file: file,
                line: line
            )
        }
    }
}
