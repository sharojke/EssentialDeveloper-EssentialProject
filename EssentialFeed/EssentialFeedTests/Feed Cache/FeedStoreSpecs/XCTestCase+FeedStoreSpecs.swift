import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(
            sut,
            toCompleteWithResult: .success(nil),
            file: file,
            line: line
        )
    }
    
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieveTwice: .success(nil), file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), into: sut)
        
        expect(
            sut,
            toCompleteWithResult: .success(CachedFeed(feed: feed, timestamp: timestamp)),
            file: file,
            line: line
        )
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), into: sut)
        
        expect(
            sut,
            toRetrieveTwice: .success(CachedFeed(feed: feed, timestamp: timestamp)),
            file: file,
            line: line
        )
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let insertionError = insert(
            (uniqueImageFeed().local, Date()),
            into: sut
        )
        
        XCTAssertNil(
            insertionError,
            "Expected to insert cache successfully",
            file: file,
            line: line
        )
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), into: sut)
        
        let insertionError = insert(
            (uniqueImageFeed().local, Date()),
            into: sut
        )
        
        XCTAssertNil(
            insertionError,
            "Expected to override cache successfully",
            file: file,
            line: line
        )
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), into: sut)
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), into: sut)
        
        expect(
            sut,
            toCompleteWithResult: .success(
                CachedFeed(
                    feed: latestFeed,
                    timestamp: latestTimestamp
                )
            ),
            file: file,
            line: line
        )
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(
            deletionError,
            "Expected empty cache deletion to succeed",
            file: file,
            line: line
        )
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        deleteCache(from: sut)
        
        expect(
            sut,
            toCompleteWithResult: .success(nil),
            file: file,
            line: line
        )
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), into: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(
            deletionError,
            "Expected non-empty cache deletion to succeed",
            file: file,
            line: line
        )
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), into: sut)
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteWithResult: .success(nil), file: file, line: line)
    }
    
    func assertThatSideEffectsRunSerially(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert(feed: uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(
            feed: uniqueImageFeed().local,
            timestamp: Date()
        ) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(
            completedOperationsInOrder,
            [op1, op2, op3],
            "Expected side-effects to run serially but operations finished in the wrong order",
            file: file,
            line: line
        )
    }
}

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(
        _ sut: FeedStore,
        toCompleteWithResult expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.retrieve { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.success(nil), .success(nil)),
                 (.failure, .failure):
                break
                
            case let (
                .success(expectedCache),
                .success(receivedCache)
            ):
                XCTAssertEqual(
                    expectedCache?.feed,
                    receivedCache?.feed,
                    file: file,
                    line: line
                )
                XCTAssertEqual(
                    expectedCache?.timestamp,
                    receivedCache?.timestamp,
                    file: file,
                    line: line
                )
                
            default:
                XCTFail(
                    "Expected \(expectedResult), got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWithResult: expectedResult, file: file, line: line)
        expect(sut, toCompleteWithResult: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    func insert(
        _ cache: (feed: [LocalFeedImage], timestamp: Date),
        into sut: FeedStore
    ) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(feed: cache.feed, timestamp: cache.timestamp) { result in
            if case let .failure(error) = result { insertionError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { result in
            if case let .failure(error) = result { deletionError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
}
