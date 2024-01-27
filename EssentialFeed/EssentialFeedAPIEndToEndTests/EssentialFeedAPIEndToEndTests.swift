import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        switch getFeedResult() {
        case .success(let imageFeed):
            XCTAssertEqual(
                imageFeed.count,
                8,
                "Expected 8 images in the test account image feed"
            )
            XCTAssertEqual(imageFeed[0], expectedImage(at: 0))
            XCTAssertEqual(imageFeed[1], expectedImage(at: 1))
            XCTAssertEqual(imageFeed[2], expectedImage(at: 2))
            XCTAssertEqual(imageFeed[3], expectedImage(at: 3))
            XCTAssertEqual(imageFeed[4], expectedImage(at: 4))
            XCTAssertEqual(imageFeed[5], expectedImage(at: 5))
            XCTAssertEqual(imageFeed[6], expectedImage(at: 6))
            XCTAssertEqual(imageFeed[7], expectedImage(at: 7))
            
        case .failure(let error):
            XCTFail("Expected success feed result, got \(error)")
            
        default:
            XCTFail("Expected success feed result, got no result instead")
        }
    }
    
    func test_endToEndTestServerGETFeedImageDataResult_matchesFixedTestAccountData() {
        switch getFeedImageDataResult() {
        case .success(let data):
            XCTAssertFalse(data.isEmpty, "Expected non-empty image data")
            
        case .failure(let error):
            XCTFail("Expected a successful image data result, got \(error) instead")
            
        default:
            XCTFail("Expected a successful image data result, got no result instead")
        }
    }
}

// MARK: - Helpers

private extension EssentialFeedAPIEndToEndTests {
    var feedTestServerURL: URL {
        return URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
    }
    
    func getFeedResult(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoader.Result? {
        let loader = RemoteFeedLoader(
            url: feedTestServerURL,
            client: ephemeralClient()
        )
        trackForMemoryLeaks(loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for completion")
        
        var receivedResult: FeedLoader.Result?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 20)
        return receivedResult
    }
    
    func getFeedImageDataResult(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedImageDataLoader.Result? {
        let loader = RemoteFeedImageDataLoader(client: ephemeralClient())
        trackForMemoryLeaks(loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for load completion")
        let feedTestServerURL = feedTestServerURL
            .appendingPathComponent("73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")
        
        var receivedResult: FeedImageDataLoader.Result?
        _ = loader.loadImageData(from: feedTestServerURL) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 20)
        
        return receivedResult
    }
    
    func expectedImage(at index: Int) -> FeedImage {
        return FeedImage(
            id: id(at: index),
            url: imageURL(at: index),
            description: description(at: index),
            location: location(at: index)
        )
    }
    
    func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }
    
    func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    func imageURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index + 1).com")!
    }
    
    func ephemeralClient(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let session = URLSession(configuration: .ephemeral)
        let client = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(client)
        return client
    }
}

// swiftlint:enable force_unwrapping
