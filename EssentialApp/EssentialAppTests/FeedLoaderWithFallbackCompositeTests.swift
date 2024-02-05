import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

private class LoaderStub: FeedLoader {
    private let result: FeedLoader.Result
    
    init(result: FeedLoader.Result) {
        self.result = result
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completion(result)
    }
}

private class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primaryLoader: FeedLoader
    private let fallbackLoader: FeedLoader
    
    init(primaryLoader: FeedLoader, fallbackLoader: FeedLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        primaryLoader.load(completion: completion)
    }
}

final class FeedLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let primaryLoader = LoaderStub(result: .success(primaryFeed))
        let fallbackLoader = LoaderStub(result: .success(fallbackFeed))
        let sut = FeedLoaderWithFallbackComposite(
            primaryLoader: primaryLoader,
            fallbackLoader: fallbackLoader
        )
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch receivedResult {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, primaryFeed)
                
            case .failure(let error):
                XCTFail("Expect to get successful result, got \(error) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}

// MARK: - Helpers

private extension FeedLoaderWithFallbackCompositeTests {
    func uniqueFeed() -> [FeedImage] {
        return [
            FeedImage(
                id: UUID(),
                url: URL(string: "http://any-url.com")!,
                description: "any",
                location: "any"
            )
        ]
    }
}

// swiftlint:enable force_unwrapping
