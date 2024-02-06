import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable large_tuple

final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private class Task: FeedImageDataLoaderTask {
        func cancel() {
        }
    }
    
    private let primaryLoader: FeedImageDataLoader
    private let fallbackLoader: FeedImageDataLoader
    
    init(primaryLoader: FeedImageDataLoader, fallbackLoader: FeedImageDataLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        _ = primaryLoader.loadImageData(from: url, completion: completion)
        return Task()
    }
}

private class LoaderSpy: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        func cancel() {
        }
    }
    
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
        return Task()
    }
}

// swiftlint:disable:next type_name
final class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_init_doestNotLoad() {
        let (_, primaryLoader, fallbackLoader) = makeSUT()
        
        XCTAssertTrue(
            primaryLoader.loadedURLs.isEmpty,
            "Expected no loaded URLs in the primary loader"
        )
        XCTAssertTrue(
            fallbackLoader.loadedURLs.isEmpty,
            "Expected no loaded URLs in the fallback loader"
        )
    }
    
    func test_load_deliversPrimaryFeedImageDataOnPrimaryLoaderSuccess() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(
            primaryLoader.loadedURLs,
            [url],
            "Expected to load URL from primary loader"
        )
        XCTAssertEqual(
            fallbackLoader.loadedURLs,
            [],
            "Expected no loaded URLs in the fallback loader"
        )
    }
}

// MARK: - Helpers

private extension FeedImageDataLoaderWithFallbackCompositeTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: FeedImageDataLoaderWithFallbackComposite,
        primaryLoader: LoaderSpy,
        fallbackLoader: LoaderSpy
        
    ) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(
            primaryLoader: primaryLoader,
            fallbackLoader: fallbackLoader
        )
        trackForMemoryLeaks(primaryLoader)
        trackForMemoryLeaks(fallbackLoader)
        trackForMemoryLeaks(sut)
        return (sut, primaryLoader, fallbackLoader)
    }
    
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential memory leak",
                file: file,
                line: line
            )
        }
    }
    
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable large_tuple
