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
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(
            data: nil,
            response: nil,
            error: error
        )
        
        let exp = expectation(description: "Wait for completion")
        
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
                
            case .success:
                XCTFail("Expected failure with \(error), got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        URLProtocolStub.stub(
            data: nil,
            response: nil,
            error: nil
        )
        
        let exp = expectation(description: "Wait for completion")
        
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case .failure:
                break
                
            case .success:
                XCTFail("Expected failure, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}

// MARK: - Helpers

extension URLSessionHTTPClientTests {
    private struct Stub {
        let error: Error?
        let data: Data?
        let response: URLResponse?
    }
    
    private class URLProtocolStub: URLProtocol {
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
}

// swiftlint:enable force_unwrapping
