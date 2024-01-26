import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
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
        let receivedError = makeErrorFor(data: nil, response: nil, error: error)
        
        compare(error: error, with: receivedError as? NSError)
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        XCTAssertNotNil(makeErrorFor(data: nil, response: nil, error: nil))
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(makeErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(makeErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPResponseWithData () {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let values = makeValuesFor(
            data: anyData(),
            response: anyHTTPURLResponse(),
            error: nil
        )
        
        XCTAssertEqual(values.data, data)
        XCTAssertEqual(values.response?.url, response.url)
        XCTAssertEqual(values.response?.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPResponseWithNilData () {
        let response = anyHTTPURLResponse()
        
        let values = makeValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(values.data, emptyData)
        XCTAssertEqual(values.response?.url, response.url)
        XCTAssertEqual(values.response?.statusCode, response.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        let task = makeSUT().get(from: url) { result in
            switch result {
            case let .failure(error as NSError) where error.code == URLError.cancelled.rawValue:
                break
                
            default:
                XCTFail("Expected cancelled result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        task.cancel()
        wait(for: [exp], timeout: 1.0)
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    struct Stub {
        let error: Error?
        let data: Data?
        let response: URLResponse?
    }
    
    class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error?
        ) {
            stub = Stub(
                error: error,
                data: data,
                response: response
            )
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let stub = Self.stub
            
            if let requestObserver = Self.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            if let data = stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub?.response {
                client?.urlProtocol(
                    self,
                    didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
            }
            
            if let error = stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
    
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    func anyData() -> Data {
        return Data("any data".utf8)
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
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        let result = makeResult(
            data: data,
            response: response,
            error: error,
            file: file,
            line: line
        )
        
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
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (data: Data?, response: HTTPURLResponse?) {
        let result = makeResult(
            data: data,
            response: response,
            error: error,
            file: file,
            line: line
        ) 
        
        switch result {
        case .success((let data, let response)):
            return (data, response)
            
        case .failure:
            XCTFail(
                "Expected success, got \(result) instead",
                file: file,
                line: line
            )
            
            return (nil, nil)
        }
    }
    
    func makeResult(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClient.Result {
        URLProtocolStub.stub(
            data: data,
            response: response,
            error: error
        )
        
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var capturedResult: HTTPClient.Result?
        
        _ = sut.get(from: anyURL()) { result in
            capturedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return capturedResult!
    }
}

// swiftlint:enable force_unwrapping
