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
        
        try? sut.save(anyData, for: anyURL)
        
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
        toCompleteWith expectedResult: Result<Void, Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()
        let receivedResult = Result { try sut.save(anyData(), for: anyURL()) }
        
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
    }
    
    func failure(
        with error: LocalFeedImageDataLoader.SaveError
    ) -> Result<Void, Error> {
        return .failure(error)
    }
}
