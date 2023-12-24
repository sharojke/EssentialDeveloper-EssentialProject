import EssentialFeed
import XCTest

// swiftlint:disable force_try
// swiftlint:disable force_unwrapping

class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Equatable, Codable {
        private let id: UUID
        private let url: URL
        private let description: String?
        private let location: String?
        
        init(localFeedImage: LocalFeedImage) {
            id = localFeedImage.id
            url = localFeedImage.url
            description = localFeedImage.description
            location = localFeedImage.location
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(
                id: id,
                url: url,
                description: description,
                location: location
            )
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        
        do {
            try fileManager.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    ) {
        let encoder = JSONEncoder()
        let cache = Cache(
            feed: feed.map(CodableFeedImage.init),
            timestamp: timestamp
        )
        
        do {
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: decoded.localFeed, timestamp: decoded.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
}

final class CodableFeedStoreTests: XCTestCase {
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
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        let firstInsertionError = insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        XCTAssertNil(firstInsertionError, "Expected successful insertion")
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert(
            (
                feed: latestFeed,
                timestamp: latestTimestamp
            ),
            into: sut
        )
        
        XCTAssertNil(latestInsertionError, "Expected successful insertion")
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
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected successful deletion")
        expect(sut, toCompleteWithResult: .empty)
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
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected successful deletion")
        expect(sut, toCompleteWithResult: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected to delete with an error")
    }
}

// MARK: - Helpers

private extension CodableFeedStoreTests {
    func makeSUT(
        storeURL: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CodableFeedStore {
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
    
    func expect(
        _ sut: CodableFeedStore,
        toCompleteWithResult expectedResult: RetrievalCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.retrieve { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
                break
                
            case let (
                .found(expectedFeed, expectedTimestamp),
                .found(receivedFeed, receivedTimestamp)
            ):
                XCTAssertEqual(expectedFeed, receivedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimestamp, receivedTimestamp, file: file, line: line)
                
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
        _ sut: CodableFeedStore,
        toRetrieveTwice expectedResult: RetrievalCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toCompleteWithResult: expectedResult, file: file, line: line)
        expect(sut, toCompleteWithResult: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    func insert(
        _ cache: (feed: [LocalFeedImage], timestamp: Date),
        into sut: CodableFeedStore
    ) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(feed: cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    func deleteCache(from sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
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
