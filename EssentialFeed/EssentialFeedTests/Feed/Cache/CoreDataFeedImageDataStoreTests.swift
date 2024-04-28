import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class CoreDataFeedImageDataStoreTests: XCTestCase, FeedImageDataStoreSpecs {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversNotFoundOnEmptyCache(on: sut, imageDataURL: imageDataURL)
        }
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversNotFoundWhenStoredDataURLDoesNotMatch(
                on: sut,
                imageDataURL: imageDataURL
            )
        }
    }
    
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversFoundDataWhenThereIsAStoredImageDataMatchingURL(
                on: sut,
                imageDataURL: imageDataURL
            )
        }
    }
    
    func test_retrieveImageData_deliversLastInsertedValue() throws {
        try makeSUT { sut, imageDataURL in
            self.assertThatRetrieveImageDataDeliversLastInsertedValueForURL(
                on: sut,
                imageDataURL: imageDataURL
            )
        }
    }
}

// MARK: - Helpers

private extension CoreDataFeedImageDataStoreTests {
    func makeSUT(
        _ test: @escaping (CoreDataFeedStore, URL) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        let exp = expectation(description: "Wait for the action")
        sut.perform {
            let imageDataURL = URL(string: "http://a-url.com")!
            insertFeedImage(with: imageDataURL, into: sut, file: file, line: line)
            test(sut, imageDataURL)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
}

private func insertFeedImage(
    with url: URL,
    into sut: CoreDataFeedStore,
    file: StaticString = #file,
    line: UInt = #line
) {
    let image = LocalFeedImage(id: UUID(), url: url, description: "any", location: "any")
    
    do {
        try sut.insert(feed: [image], timestamp: Date())
    } catch {
        XCTFail(
            "Failed to insert feed image with URL \(url) - error: \(error)",
            file: file,
            line: line
        )
    }
}

// swiftlint:enable force_unwrapping
