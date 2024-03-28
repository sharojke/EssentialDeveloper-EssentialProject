public protocol FeedImageDataStore {
    typealias RetrievalResult = Swift.Result<Data?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>
    
    func retrieve(dataForURL url: URL) throws -> Data?
    func insert(_ data: Data, for url: URL) throws
    
    @available(*, deprecated)
    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void)
    
    @available(*, deprecated)
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
}

public extension FeedImageDataStore {
    func retrieve(dataForURL url: URL) throws -> Data? {
        let group = DispatchGroup()
        group.enter()
        
        var result: RetrievalResult?
        retrieve(dataForURL: url) { receivedResult in
            result = receivedResult
            group.leave()
        }
        
        group.wait()
        return try result?.get()
    }
    
    func insert(_ data: Data, for url: URL) throws {
        let group = DispatchGroup()
        group.enter()
        
        var result: InsertionResult?
        insert(data, for: url) { receivedResult in
            result = receivedResult
            group.leave()
        }
        
        group.wait()
        try result?.get()
    }
    
    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void) {}
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {}
}
