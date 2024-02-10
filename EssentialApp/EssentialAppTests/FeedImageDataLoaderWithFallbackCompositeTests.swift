import EssentialApp
import EssentialFeed
import XCTest

// swiftlint:disable large_tuple

// swiftlint:disable:next type_name
final class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase, FeedImageDataLoaderTestCase {
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
    
    func test_cancelLoadImageData_cancelsFallbackLoaderTaskAfterPrimaryLoaderFailure() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        let task = sut.loadImageData(from: url) { _ in }
        primaryLoader.complete(with: anyNSError())
        task.cancel()
        
        XCTAssertEqual(
            primaryLoader.cancelledURLs,
            [],
            "Expected no cancelled URLs in the primary loader"
        )
        XCTAssertEqual(
            fallbackLoader.cancelledURLs,
            [url],
            "Expected to cancel URL from fallback loader"
        )
    }
    
    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() {
        let data = anyData()
        let (sut, primaryLoader, _) = makeSUT()
        
        expect(sut, toCompleteWith: .success(data)) {
            primaryLoader.complete(with: data)
        }
    }
    
    func test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess() {
        let fallbackData = anyData()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        expect(sut, toCompleteWith: .success(fallbackData)) {
            primaryLoader.complete(with: anyNSError())
            fallbackLoader.complete(with: fallbackData)
        }
    }
    
    func test_loadImageData_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() {
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(anyNSError())) {
            primaryLoader.complete(with: anyNSError())
            fallbackLoader.complete(with: anyNSError())
        }
    }
}

// MARK: - Helpers

private extension FeedImageDataLoaderWithFallbackCompositeTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: FeedImageDataLoaderWithFallbackComposite,
        primaryLoader: FeedImageDataLoaderSpy,
        fallbackLoader: FeedImageDataLoaderSpy
    ) {
        let primaryLoader = FeedImageDataLoaderSpy()
        let fallbackLoader = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(
            primaryLoader: primaryLoader,
            fallbackLoader: fallbackLoader
        )
        trackForMemoryLeaks(primaryLoader)
        trackForMemoryLeaks(fallbackLoader)
        trackForMemoryLeaks(sut)
        return (sut, primaryLoader, fallbackLoader)
    }
}

// swiftlint:enable large_tuple
