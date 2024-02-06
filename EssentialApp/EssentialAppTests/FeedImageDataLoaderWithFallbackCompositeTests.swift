import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
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
        return primaryLoader.loadImageData(from: url, completion: completion)
    }
}

private class LoaderStub: FeedImageDataLoader {
    private final class TaskWrapper: FeedImageDataLoaderTask {
        func cancel() {
        }
    }
    
    let result: FeedImageDataLoader.Result
    
    init(result: FeedImageDataLoader.Result) {
        self.result = result
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        completion(result)
        return TaskWrapper()
    }
}

// swiftlint:disable:next type_name
final class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedImageDataOnPrimaryLoaderSuccess() {
        let primaryData = anyData()
        let fallbackData = anyData()
        let primaryLoader = LoaderStub(result: .success(primaryData))
        let fallbackLoader = LoaderStub(result: .success(fallbackData))
        let sut = FeedImageDataLoaderWithFallbackComposite(
            primaryLoader: primaryLoader,
            fallbackLoader: fallbackLoader
        )
        
        let exp = expectation(description: "Wait for load image data completion")
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch receivedResult {
            case .success(let receivedData):
                XCTAssertEqual(receivedData, primaryData)
                
            case .failure(let error):
                XCTFail("Expected to finish successfully, got \(error) instead")
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}

// MARK: - Helpers

private extension FeedImageDataLoaderWithFallbackCompositeTests {
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
    
    func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}

// swiftlint:enable force_unwrapping
