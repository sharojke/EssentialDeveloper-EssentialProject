import EssentialFeed
import XCTest

private final class StoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(data: Data, for: URL)
    }
    
    private var retrievalCompletions = [(FeedImageDataStore.RetrievalResult) -> Void]()
    private(set) var receivedMessages = [Message]()
    
    func retrieve(
        dataForURL url: URL,
        completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void
    ) {
        receivedMessages.append(.retrieve(dataFor: url))
        retrievalCompletions.append(completion)
    }
    
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        receivedMessages.append(.insert(data: data, for: url))
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrieval(with data: Data?, at index: Int = 0) {
        retrievalCompletions[index](.success(data))
    }
}

final class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsStoredDataFromURL() {
        let url = anyURL()
        let (sut, store) = makeSUT()
        
        _ = sut.loadImageData(from: url) { _ in }
        
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
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, store) = makeSUT()
        let anyFoundData = anyData()
            
        var receivedResults = [(Result<Data, Error>)]()
        let task = sut.loadImageData(from: anyURL()) { receivedResults.append($0) }
        task.cancel()
        
        store.completeRetrieval(with: anyFoundData)
        store.completeRetrieval(with: nil)
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = StoreSpy()
        var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: store)
        
        var receivedResults = [(Result<Data, Error>)]()
        _ = sut?.loadImageData(from: anyURL()) { receivedResults.append($0) }
        
        sut = nil
        store.completeRetrieval(with: anyData())
        store.completeRetrieval(with: nil)
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_loadDataFromURL_requestsImageDataInsertionForURL() {
        let (sut, store) = makeSUT()
        let anyData = anyData()
        let anyURL = anyURL()
        
        sut.save(anyData, for: anyURL) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.insert(data: anyData, for: anyURL)])
    }
}

// MARK: - Helpers

private extension LoadFeedImageDataFromCacheUseCaseTests {
    func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedImageDataLoader, store: StoreSpy) {
        let store = StoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    func expect(
        _ sut: LocalFeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
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
            
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1)
    }
    
    func failure(with error: LocalFeedImageDataLoader.LoadError) -> FeedImageDataLoader.Result {
        return .failure(error)
    }
}
