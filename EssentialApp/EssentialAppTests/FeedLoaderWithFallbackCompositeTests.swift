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
        primaryLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                completion(.success(feed))
                
            case .failure:
                self?.fallbackLoader.load(completion: completion)
            }
        }
    }
}

final class FeedLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(
            primaryResult: .success(primaryFeed),
            fallbackResult: .success(fallbackFeed)
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
    
    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(
            primaryResult: .failure(anyNSError()),
            fallbackResult: .success(fallbackFeed)
        )
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch receivedResult {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, fallbackFeed)
                
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
    func makeSUT(
        primaryResult: FeedLoader.Result,
        fallbackResult: FeedLoader.Result,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoader {
        let primaryLoader = LoaderStub(result: primaryResult)
        let fallbackLoader = LoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(
            primaryLoader: primaryLoader,
            fallbackLoader: fallbackLoader
        )
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
    
    func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

// swiftlint:enable force_unwrapping
