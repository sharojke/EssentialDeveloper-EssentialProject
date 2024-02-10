import EssentialFeed
import XCTest

final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    
    init(decoratee: FeedImageDataLoader) {
        self.decoratee = decoratee
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        return decoratee.loadImageData(from: url, completion: completion)
    }
}

private class LoaderSpy: FeedImageDataLoader {
    private struct Task: FeedImageDataLoaderTask {
        var callback: () -> Void
        
        func cancel() {
            callback()
        }
    }
    
    private(set) var cancelledURLs = [URL]()
    private var messages = [
        (url: URL, completion: (FeedImageDataLoader.Result) -> Void)
    ]()
    
    var loadedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with data: Data, at index: Int = 0) {
        messages[index].completion(.success(data))
    }
}

final class FeedImageDataLoaderCacheDecoratorTests: XCTestCase {
    func test_init_doestNotLoad() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loadedURLs.isEmpty)
    }
    
    func test_loadImageData_loadsFromLoader() {
        let url = anyURL()
        let (sut, loader) = makeSUT()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(loader.loadedURLs, [url])
    }
    
    func test_cancelLoadImageData_cancelsLoaderTask() {
        let url = anyURL()
        let (sut, loader) = makeSUT()
        
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()
        
        XCTAssertEqual(loader.cancelledURLs, [url])
    }
    
    func test_loadImageData_deliversDataOnLoaderSuccess() {
        let data = anyData()
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .success(data)) {
            loader.complete(with: data)
        }
    }
    
    func test_loadImageData_deliversErrorOnLoaderFailure() {
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(anyNSError())) {
            loader.complete(with: anyNSError())
        }
    }
}

// MARK: - Helpers

private extension FeedImageDataLoaderCacheDecoratorTests {
    func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: FeedImageDataLoader,
        loader: LoaderSpy
    ) {
        let loader = LoaderSpy()
        let sut = FeedImageDataLoaderCacheDecorator(decoratee: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    func expect(
        _ sut: FeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load")
        
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(
                    receivedData,
                    expectedData,
                    file: file,
                    line: line
                )
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail(
                    "Expected to get \(expectedResult), got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1)
    }
}
