import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable large_tuple

final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private class Task: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
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
        var task = Task()
        task.wrapped = primaryLoader.loadImageData(from: url) { [weak self] receivedResult in
            switch receivedResult {
            case .success:
                break
                
            case .failure:
                _ = self?.fallbackLoader.loadImageData(from: url) { _ in }
            }
        }
        
        return task
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
    
    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
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
    
    func test_loadImageData_loadsFromFallbackOnPrimaryLoaderFailure() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        _ = sut.loadImageData(from: url) { _ in }
        primaryLoader.complete(with: anyNSError())
        
        XCTAssertEqual(
            primaryLoader.loadedURLs,
            [url],
            "Expected to load URL from primary loader"
        )
        XCTAssertEqual(
            fallbackLoader.loadedURLs,
            [url],
            "Expected to load URL from fallback loader"
        )
    }
    
    func test_cancelLoadImageData_cancelsPrimaryLoaderTask() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()
        
        XCTAssertEqual(
            primaryLoader.cancelledURLs,
            [url],
            "Expected to cancel URL from primary loader"
        )
        XCTAssertEqual(
            fallbackLoader.cancelledURLs,
            [],
            "Expected no cancelled URLs in the fallback loader"
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
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable large_tuple
