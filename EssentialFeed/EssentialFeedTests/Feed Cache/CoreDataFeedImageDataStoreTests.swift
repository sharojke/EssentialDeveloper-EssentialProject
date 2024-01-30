import EssentialFeed
import XCTest

// swiftlint:disable force_try
// swiftlint:disable force_unwrapping

final class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()
        
        expect(sut, toCompleteRetrievalWith: notFound(), for: anyURL())
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() {
        let sut = makeSUT()
        let url = anyURL()
        let notMatchingURL = URL(string: "http://another-url.com")!
        
        insert(anyData(), for: url, into: sut)
        
        expect(sut, toCompleteRetrievalWith: notFound(), for: notMatchingURL)
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
    
    func insert(
        _ data: Data,
        for url: URL,
        into sut: CoreDataFeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for cache insertion")
        let image = localImage(url: url)
        
        sut.insert(
            feed: [image],
            timestamp: Date()
        ) { result in
            switch result {
            case .success:
                sut.insert(data, for: url) { result in
                    if case .failure(let error) = result {
                        XCTFail(
                            "Failed to insert \(data) with error \(error)",
                            file: file,
                            line: line
                        )
                    }
                }
                
            case .failure(let error):
                XCTFail(
                    "Failed to save \(image) with error \(error)",
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
    
    func localImage(url: URL) -> LocalFeedImage {
        return LocalFeedImage(
            id: UUID(),
            url: url,
            description: "any",
            location: "any"
        )
    }
}

// swiftlint:enable force_try
// swiftlint:enable force_unwrapping
