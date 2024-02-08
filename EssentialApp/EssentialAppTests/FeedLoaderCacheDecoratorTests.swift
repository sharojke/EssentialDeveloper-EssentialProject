import EssentialFeed
import XCTest

protocol FeedCache {
    typealias Result = Swift.Result<Void, Error>
    
    func save(
        _ feed: [FeedImage],
        completion: @escaping (Result) -> Void
    )
}

private final class FeedCacheSpy: FeedCache {
    enum Message: Equatable {
        case save([FeedImage])
    }
    
    private(set) var messages = [Message]()
    
    func save(
        _ feed: [FeedImage],
        completion: @escaping (FeedCache.Result) -> Void
    ) {
        messages.append(.save(feed))
    }
}

final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let cache: FeedCache
    
    init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        decoratee.load { [weak self] result in
            completion(result.map { feed in
                self?.cache.save(feed) { _ in }
                return feed
            })
        }
    }
}

final class FeedLoaderCacheDecoratorTests: XCTestCase, FeedLoaderTestCase {
    func test_load_deliversFeedOnLoaderSuccess() {
        let feed = uniqueFeed()
        let sut = makeSUT(loaderResult: .success(feed))
        
        expect(sut, toCompleteWith: .success(feed))
    }
    
    func test_load_deliversErrorOnLoaderFailure() {
        let sut = makeSUT(loaderResult: .failure(anyNSError()))
        
        expect(sut, toCompleteWith: .failure(anyNSError()))
    }
    
    func test_load_cachesFeedOnLoaderSuccess() {
        let cache = FeedCacheSpy()
        let feed = uniqueFeed()
        let sut = makeSUT(loaderResult: .success(feed), cache: cache)
        
        sut.load { _ in }
        
        XCTAssertEqual(cache.messages, [.save(feed)])
    }
}

// MARK: - Helpers

private extension FeedLoaderCacheDecoratorTests {
    func makeSUT(
        loaderResult: FeedLoader.Result,
        cache: FeedCacheSpy = FeedCacheSpy(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedLoader {
        let loader = FeedLoaderStub(result: loaderResult)
        let sut = FeedLoaderCacheDecorator(decoratee: loader, cache: cache)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
