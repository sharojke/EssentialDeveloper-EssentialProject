import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws {
        try makeSUT { sut in
            expect(sut, toCompleteRetrievalWith: notFound(), for: anyURL())
        }
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws {
        try makeSUT { sut in
            let url = anyURL()
            let notMatchingURL = URL(string: "http://another-url.com")!
            
            insert(anyData(), for: url, into: sut)
            
            expect(sut, toCompleteRetrievalWith: notFound(), for: notMatchingURL)
        }
    }
    
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws {
        try makeSUT { sut in
            let storedData = anyData()
            let matchingURL = URL(string: "http://a-url.com")!
            
            insert(storedData, for: matchingURL, into: sut)
            
            expect(sut, toCompleteRetrievalWith: found(storedData), for: matchingURL)
        }
    }
    
    func test_retrieveImageData_deliversLastInsertedValue() throws {
        try makeSUT { sut in
            let firstData = anyData()
            let lastData = anyData()
            let url = URL(string: "http://a-url.com")!
            
            insert(firstData, for: url, into: sut)
            insert(lastData, for: url, into: sut)
            
            expect(sut, toCompleteRetrievalWith: found(lastData), for: url)
        }
    }
}

// MARK: - Helpers

private extension CoreDataFeedImageDataStoreTests {
    func makeSUT(
        _ test: @escaping (CoreDataFeedStore) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        let exp = expectation(description: "Wait for the action")
        sut.perform {
            test(sut)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
}

private func expect(
    _ sut: CoreDataFeedStore,
    toCompleteRetrievalWith expectedResult: FeedImageDataStore.RetrievalResult,
    for url: URL,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let receivedResult = Result { try sut.retrieve(dataForURL: url) }
    
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
}

private func insert(
    _ data: Data,
    for url: URL,
    into sut: CoreDataFeedStore,
    file: StaticString = #file,
    line: UInt = #line
) {
    let image = localImage(url: url)
    
    do {
        try sut.insert(feed: [image], timestamp: Date())
        try sut.insert(data, for: url)
    } catch {
        XCTFail(
            "Failed to insert \(data) with error \(error)",
            file: file,
            line: line
        )
    }
}

private func notFound() -> FeedImageDataStore.RetrievalResult {
    return .success(nil)
}

private func found(_ data: Data) -> FeedImageDataStore.RetrievalResult {
    return .success(data)
}

private func localImage(url: URL) -> LocalFeedImage {
    return LocalFeedImage(
        id: UUID(),
        url: url,
        description: "any",
        location: "any"
    )
}

// swiftlint:enable force_unwrapping
