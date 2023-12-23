import EssentialFeed
import XCTest

// swiftlint:disable force_try
// swiftlint:disable force_unwrapping

class CodableFeedStore {
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
    
    func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping FeedStore.InsertionCompletion
    ) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(
            Cache(
                feed: feed.map(CodableFeedImage.init),
                timestamp: timestamp
            )
        )
        try! encoded.write(to: storeURL)
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: decoded.localFeed, timestamp: decoded.timestamp))
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        try? FileManager.default.removeItem(at: storeURL())
    }
    
    override func tearDown() {
        super.tearDown()
        
        try? FileManager.default.removeItem(at: storeURL())
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
                
            default:
                XCTFail("Expected .empty, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                    
                default:
                    XCTFail("Expected the same .empty result, got \(firstResult) and \(secondResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.insert(feed: feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected to be inserted successfully")
            
            sut.retrieve { result in
                switch result {
                case .found(let receivedFeed, let receivedTimestamp):
                    XCTAssertEqual(receivedFeed, feed)
                    XCTAssertEqual(receivedTimestamp, timestamp)
                    
                default:
                    XCTFail("Expected .found result, got \(result) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}

// MARK: - Helpers

private extension CodableFeedStoreTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CodableFeedStore {
        let storeURL = storeURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func storeURL() -> URL {
        return FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )
        .first!
        .appendingPathComponent("image-feed.store")
    }
}

// swiftlint:enable force_try
// swiftlint:enable force_unwrapping
