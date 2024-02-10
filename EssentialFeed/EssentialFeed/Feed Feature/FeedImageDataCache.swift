public protocol FeedImageDataCache {
    typealias Result = Swift.Result<Void, Swift.Error>
    
    func save(
        _ data: Data,
        for url: URL,
        completion: @escaping (Result) -> Void
    )
}
