import EssentialFeed
import XCTest

// swiftlint:disable force_try

final class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()
        
        expect(
            sut,
            toCompleteRetrievalWith: notFound(),
            for: anyURL()
        )
    }
}

// MARK: - Helpers

private extension CoreDataFeedImageDataStoreTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func expect(
        _ sut: CoreDataFeedStore,
        toCompleteRetrievalWith expectedResult: FeedImageDataStore.RetrievalResult,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        sut.retrieve(dataForURL: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(
                    receivedData,
                    expectedData,
                    file: file,
                    line: line
                )
                
            default:
                XCTFail(
                    "Expected to complete with \(expectedResult), got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func notFound() -> FeedImageDataStore.RetrievalResult {
        return .success(nil)
    }
}

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(_ data: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertionResult) -> Void) {
    }

    public func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
        completion(.success(nil))
    }
}

// swiftlint:enable force_try
