import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class URLSessionHTTPClient {
    struct UnexpectedValuesRepresentation: Error {}
    
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(
        from url: URL,
        completion: @escaping (HTTPClientResult) -> Void
    ) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        .resume()
    }
}

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
        
        makeSUT().get(from: url) { _ in }
        
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
        XCTAssertNotNil(makeErrorFor(data: nil, response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(makeErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
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
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let stub = Self.stub
            
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
    ) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
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
        URLProtocolStub.stub(
            data: data,
            response: response,
            error: error
        )
        
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var capturedError: Error?
        
        sut.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                capturedError = error
                
            case .success:
                XCTFail(
                    "Expected failure, got \(result) instead",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return capturedError
    }
}

// swiftlint:enable force_unwrapping
