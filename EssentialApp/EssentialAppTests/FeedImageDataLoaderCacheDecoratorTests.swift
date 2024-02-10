import EssentialFeed
import XCTest

final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache
    
    init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        return decoratee.loadImageData(from: url) { [weak self] result in
            completion(result.map { data in
                self?.cache.save(data, for: url) { _ in }
                return data
            })
        }
    }
}

protocol FeedImageDataCache {
    typealias Result = Swift.Result<Void, Swift.Error>
    
    func save(
        _ data: Data,
        for url: URL,
        completion: @escaping (Result) -> Void
    )
}

private final class FeedImageDataCacheSpy: FeedImageDataCache {
    enum Message: Equatable {
        case save(Data, URL)
    }
    
    private(set) var messages = [Message]()
    
    func save(
        _ data: Data,
        for url: URL,
        completion: @escaping (FeedImageDataCache.Result) -> Void
    ) {
        messages.append(.save(data, url))
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
    
    func test_loadImageData_cachesFeedImageDataOnLoaderSuccess() {
        let data = anyData()
        let url = anyURL()
        let cache = FeedImageDataCacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        
        _ = sut.loadImageData(from: url) { _ in }
        loader.complete(with: data)
        
        XCTAssertEqual(cache.messages, [.save(data, url)])
    }
    
    func test_loadImageData_doesNotCacheFeedImageDataOnLoaderFailure() {
        let url = anyURL()
        let cache = FeedImageDataCacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        
        _ = sut.loadImageData(from: url) { _ in }
        loader.complete(with: anyNSError())
        
        XCTAssertTrue(cache.messages.isEmpty)
    }
}

// MARK: - Helpers

private extension FeedImageDataLoaderCacheDecoratorTests {
    func makeSUT(
        cache: FeedImageDataCacheSpy = FeedImageDataCacheSpy(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: FeedImageDataLoader,
        loader: FeedImageDataLoaderSpy
    ) {
        let loader = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderCacheDecorator(
            decoratee: loader,
            cache: cache
        )
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
