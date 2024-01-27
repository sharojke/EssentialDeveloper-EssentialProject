import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable large_tuple

final class URLSessionHTTPClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        _ = makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let error = anyNSError()
        let receivedError = makeErrorFor((data: nil, response: nil, error: error))
        
        compare(error: error, with: receivedError as? NSError)
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        XCTAssertNotNil(makeErrorFor((data: nil, response: nil, error: nil)))
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(makeErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(makeErrorFor((data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(makeErrorFor((data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(makeErrorFor((data: anyData(), response: nil, error: anyNSError())))
        XCTAssertNotNil(makeErrorFor((data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(makeErrorFor((data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(makeErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(makeErrorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(makeErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }
    
    func test_getFromURL_succeedsOnHTTPResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let values = makeValuesFor((
            data: anyData(),
            response: anyHTTPURLResponse(),
            error: nil
        ))
        
        XCTAssertEqual(values?.data, data)
        XCTAssertEqual(values?.response.url, response.url)
        XCTAssertEqual(values?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPResponseWithNilData () {
        let response = anyHTTPURLResponse()
        
        let values = makeValuesFor((data: nil, response: response, error: nil))
        
        let emptyData = Data()
        XCTAssertEqual(values?.data, emptyData)
        XCTAssertEqual(values?.response.url, response.url)
        XCTAssertEqual(values?.response.statusCode, response.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let receivedError = makeErrorFor(taskHandler: { $0.cancel() }) as NSError?
        
        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(
            url: anyURL(),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }
    
    func makeErrorFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = makeResult(values, taskHandler: taskHandler, file: file, line: line)
        
        switch result {
        case .failure(let error):
            return error
            
        case .success:
            XCTFail(
                "Expected failure, got \(result) instead",
                file: file,
                line: line
            )
            
            return nil
        }
    }
    
    func makeValuesFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = makeResult(values, file: file, line: line)
        
        switch result {
        case .success((let data, let response)):
            return (data, response)
            
        case .failure:
            XCTFail(
                "Expected success, got \(result) instead",
                file: file,
                line: line
            )
            
            return nil
        }
    }
    
    func makeResult(
        _ values: (data: Data?, response: URLResponse?, error: Error?)?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var capturedResult: HTTPClient.Result?
        
        taskHandler(sut.get(from: anyURL()) { result in
            capturedResult = result
            exp.fulfill()
        })
        
        wait(for: [exp], timeout: 1.0)
        return capturedResult!
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable large_tuple
