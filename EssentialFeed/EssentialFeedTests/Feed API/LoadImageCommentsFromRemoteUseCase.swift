import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class LoadImageCommentsFromRemoteUseCase: XCTestCase {
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
    
    func test_load_deliversErrorOnNon2xxHTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 150, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            execute(
                sut,
                toCompleteWithResult: failure(.invalidData),
                when: {
                    let json = makeItemsJSON([])
                    client.complete(withStatusCode: code, data: json, at: index)
                }
            )
        }
    }
    
    func test_load_deliversErrorOn2xxHTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        let samples = [200, 201, 250, 280, 299]
        
        samples.enumerated().forEach { index, code in
            execute(
                sut,
                toCompleteWithResult: failure(.invalidData),
                when: {
                    let invalidJSON = Data("invalid.json".utf8)
                    client.complete(withStatusCode: code, data: invalidJSON, at: index)
                }
            )
        }
    }
    
    func test_load_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let samples = [200, 201, 250, 280, 299]
        
        samples.enumerated().forEach { index, code in
            execute(
                sut,
                toCompleteWithResult: .success([]),
                when: {
                    let emptyJSONList = makeItemsJSON([])
                    client.complete(withStatusCode: code, data: emptyJSONList, at: index)
                }
            )
        }
    }
    
    func test_load_deliversItemsOn2xxHTTPResponseWithNotEmptyJSONList() {
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
        let samples = [200, 201, 250, 280, 299]
        
        samples.enumerated().forEach { index, code in
            execute(
                sut,
                toCompleteWithResult: .success(items),
                when: {
                    let json = makeItemsJSON([item1.json, item2.json])
                    client.complete(withStatusCode: code, data: json, at: index)
                }
            )
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteImageCommentsLoader? = RemoteImageCommentsLoader(
            url: url,
            client: client
        )
        
        var capturedResults = [RemoteImageCommentsLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
}

// MARK: - Helpers

extension LoadImageCommentsFromRemoteUseCase {
    private func makeSUT(
        url: URL = URL(string: "http://url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteImageCommentsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func failure(
        _ error: RemoteImageCommentsLoader.Error
    ) -> RemoteImageCommentsLoader.Result {
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
        _ sut: RemoteImageCommentsLoader,
        toCompleteWithResult expectedResult: RemoteImageCommentsLoader.Result,
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
                .failure(receivedError as RemoteImageCommentsLoader.Error),
                .failure(expectedError as RemoteImageCommentsLoader.Error)
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
