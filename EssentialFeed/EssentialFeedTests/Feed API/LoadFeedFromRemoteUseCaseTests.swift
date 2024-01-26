import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

private class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        func cancel() {}
    }
    
    private var messages = [
        (
            url: URL,
            completion: (HTTPClient.Result) -> Void
        )
    ]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(
        from url: URL,
        completion: @escaping (HTTPClient.Result) -> Void
    ) -> EssentialFeed.HTTPClientTask {
        messages.append((url, completion))
        return Task()
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(
        with statusCode: Int,
        data: Data,
        at index: Int = 0
    ) {
        let response = HTTPURLResponse(
            url: messages[index].url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        messages[index].completion(.success((data, response)))
    }
}

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "http://given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromUrlTwice() {
        let url = URL(string: "http://given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        execute(
            sut,
            toCompleteWithResult: failure(.connectivity),
            when: {
                let clientError = NSError(domain: "Test", code: 0)
                client.complete(with: clientError)
            }
        )
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            execute(
                sut,
                toCompleteWithResult: failure(.invalidData),
                when: {
                    let json = makeItemsJSON([])
                    client.complete(with: code, data: json, at: index)
                }
            )
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        execute(
            sut,
            toCompleteWithResult: failure(.invalidData),
            when: {
                let invalidJSON = Data("invalid.json".utf8)
                client.complete(with: 200, data: invalidJSON)
            }
        )
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        execute(
            sut,
            toCompleteWithResult: .success([]),
            when: {
                let emptyJSONList = makeItemsJSON([])
                client.complete(with: 200, data: emptyJSONList)
            }
        )
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithNotEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://url.com")!
        )
        
        let item2 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://url.com")!,
            description: "a description",
            location: "a location"
        )
        
        let items = [item1.model, item2.model]
        
        execute(
            sut,
            toCompleteWithResult: .success(items),
            when: {
                let json = makeItemsJSON([item1.json, item2.json])
                client.complete(with: 200, data: json)
            }
        )
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(
            url: url,
            client: client
        )
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(with: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
}

// MARK: - Helpers

extension LoadFeedFromRemoteUseCaseTests {
    private func makeSUT(
        url: URL = URL(string: "http://url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func failure(
        _ error: RemoteFeedLoader.Error
    ) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private func makeItem(
        id: UUID,
        imageURL: URL,
        description: String? = nil,
        location: String? = nil
    ) -> (model: FeedImage, json: [String: Any]) {
        let model = FeedImage(
            id: id,
            url: imageURL,
            description: description,
            location: location
        )
        
        let json = [
            "id": model.id.uuidString,
            "description": model.description,
            "location": model.location,
            "image": model.url.absoluteString
        ].compactMapValues { $0 }
        
        return (model, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func execute(
        _ sut: RemoteFeedLoader,
        toCompleteWithResult expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(
                    receivedItems,
                    expectedItems,
                    file: file,
                    line: line
                )
                
            case let (
                .failure(receivedError as RemoteFeedLoader.Error),
                .failure(expectedError as RemoteFeedLoader.Error)
            ):
                XCTAssertEqual(
                    receivedError,
                    expectedError,
                    file: file,
                    line: line
                )
                
            default:
                XCTFail(
                    "Expected result \(expectedResult) and got \(receivedResult) instead.",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
