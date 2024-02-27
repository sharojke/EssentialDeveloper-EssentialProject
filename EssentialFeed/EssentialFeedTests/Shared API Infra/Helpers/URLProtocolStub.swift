import EssentialFeed

class URLProtocolStub: URLProtocol {
    struct Stub {
        let error: Error?
        let data: Data?
        let response: URLResponse?
        let requestObserver: ((URLRequest) -> Void)?
    }
    
    private static var _stub: Stub?
    private static var stub: Stub? {
        get { return queue.sync { _stub } }
        set { queue.sync { _stub = newValue } }
    }
    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
    
    static func stub(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        stub = Stub(
            error: error,
            data: data,
            response: response,
            requestObserver: nil
        )
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        stub = Stub(error: nil, data: nil, response: nil, requestObserver: observer)
    }
    
    static func removeStub() {
        stub = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let stub = Self.stub else { return }
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        
        stub.requestObserver?(request)
    }
    
    override func stopLoading() {}
}
