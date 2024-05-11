import EssentialFeed
import XCTest

final class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsStoredDataFromURL() {
        let url = anyURL()
        let (sut, store) = makeSUT()
        
        _ = try? sut.loadImageData(from: url)
        
        XCTAssertEqual(
            store.receivedMessages,
            [.retrieve(dataFor: url)]
        )
    }
    
    func test_loadImageDataFromURL_failsOnStoreError() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: failure(with: .failed)) {
            let retrievalError = anyNSError()
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    func test_loadImageDataFromURL_deliversNotFoundErrorOnNotFound() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: failure(with: .notFound)) {
            store.completeRetrieval(with: nil)
        }
    }
    
    func test_loadImageDataFromURL_deliversStoredDataOnFoundData() {
        let (sut, store) = makeSUT()
        let anyFoundData = anyData()
        
        expect(sut, toCompleteWith: .success(anyFoundData)) {
            store.completeRetrieval(with: anyFoundData)
        }
    }
}

// MARK: - Helpers

private extension LoadFeedImageDataFromCacheUseCaseTests {
    func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
        let store = FeedImageDataStoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    func expect(
        _ sut: LocalFeedImageDataLoader,
        toCompleteWith expectedResult: Result<Data, Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()
        let receivedResult = Result { try sut.loadImageData(from: anyURL()) }
        
        switch (receivedResult, expectedResult) {
        case (.success(let receivedData), .success(let expectedData)):
            XCTAssertEqual(
                receivedData,
                expectedData,
                file: file,
                line: line
            )
            
        case (
            .failure(let receivedError as LocalFeedImageDataLoader.LoadError),
            .failure(let expectedError as LocalFeedImageDataLoader.LoadError)
        ):
            XCTAssertEqual(
                receivedError,
                expectedError,
                file: file,
                line: line
            )
            
        default:
            XCTFail(
                "Expected result \(expectedResult), got \(receivedResult) instead",
                file: file,
                line: line
            )
        }
    }
    
    func failure(with error: LocalFeedImageDataLoader.LoadError) -> Result<Data, Error> {
        return .failure(error)
    }
}
