import EssentialFeed
import XCTest

final class CacheFeedImageDataUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_saveImageDataForURL_requestsImageDataInsertionForURL() {
        let (sut, store) = makeSUT()
        let anyData = anyData()
        let anyURL = anyURL()
        
        sut.save(anyData, for: anyURL) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.insert(data: anyData, for: anyURL)])
    }
    
    func test_saveImageDataForURL_failsOnStoreInsertionError() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: failure(with: .failed)) {
            store.completeInsertion(with: anyNSError())
        }
    }
    
    func test_saveImageDataForURL_succeedsOnSuccessfulStoreInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success(Void()), when: {
            store.completeInsertionSuccessfully()
        })
    }
    
    func test_saveImageDataForURL_doesNotReceiveResultAfterSUTHasBeenDeallocated() {
        let store = FeedImageDataStoreSpy()
        var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: store)
        
        var received = [LocalFeedImageDataLoader.SaveResult]()
        sut?.save(anyData(), for: anyURL()) { result in
            received.append(result)
        }
        sut = nil
        store.completeInsertionSuccessfully()
        
        XCTAssertTrue(received.isEmpty)
    }
}

// MARK: - Helpers

private extension CacheFeedImageDataUseCaseTests {
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
        toCompleteWith expectedResult: LocalFeedImageDataLoader.SaveResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.save(anyData(), for: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success):
                break
                
            case (
                .failure(let receivedError as LocalFeedImageDataLoader.SaveError),
                .failure(let expectedError as LocalFeedImageDataLoader.SaveError)
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
    
    func failure(
        with error: LocalFeedImageDataLoader.SaveError
    ) -> LocalFeedImageDataLoader.SaveResult {
        return .failure(error)
    }
}
