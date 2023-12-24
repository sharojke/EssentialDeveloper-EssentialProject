import EssentialFeed
import XCTest

// swiftlint:disable force_try
// swiftlint:disable force_unwrapping

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        expect(makeSUT(), toCompleteWithResult: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), into: sut)
        
        expect(sut, toCompleteWithResult: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), into: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "failure".write(
            to: storeURL,
            atomically: false,
            encoding: .utf8
        )
        
        expect(sut, toCompleteWithResult: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "failure".write(
            to: storeURL,
            atomically: false,
            encoding: .utf8
        )
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let insertionError = insert((uniqueImageFeed().local, Date()), into: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), into: sut)
        
        let insertionError = insert((uniqueImageFeed().local, Date()), into: sut)
        
        XCTAssertNil(insertionError, "Expected to override cache successfully")
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), into: sut)
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), into: sut)
        
        expect(
            sut,
            toCompleteWithResult: .found(
                feed: latestFeed,
                timestamp: latestTimestamp
            )
        )
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        let insertionError = insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        
        expect(sut, toCompleteWithResult: .empty)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected successful deletion")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteWithResult: .empty)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected successful deletion")
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteWithResult: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected to delete with an error")
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteWithResult: .empty)
    }
    
    func test_storeSideEffects_runeSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let exp1 = expectation(description: "Operation 1")
        sut.insert(
            feed: uniqueImageFeed().local,
            timestamp: Date()
        ) { _ in
            completedOperationsInOrder.append(exp1)
            exp1.fulfill()
        }
        
        let exp2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(exp2)
            exp2.fulfill()
        }
        
        let exp3 = expectation(description: "Operation 3")
        sut.insert(
            feed: uniqueImageFeed().local,
            timestamp: Date()
        ) { _ in
            completedOperationsInOrder.append(exp3)
            exp3.fulfill()
        }
        
        wait(for: [exp1, exp2, exp3], timeout: 5)
        
        XCTAssertEqual(
            completedOperationsInOrder,
            [exp1, exp2, exp3],
            "Expected side-effects to run serially, but they've finished in a wrong order"
        )
    }
}

// MARK: - Helpers

private extension CodableFeedStoreTests {
    func makeSUT(
        storeURL: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedStore {
        let storeURL = storeURL ?? testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        .first!
        .appendingPathComponent("\(type(of: self)).store")
    }
    
    func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    func cachesDirectory() -> URL {
        return FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
    }
}

// swiftlint:enable force_try
// swiftlint:enable force_unwrapping
