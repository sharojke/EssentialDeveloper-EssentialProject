public final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

// MARK: - Load

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    public typealias LoadResult = FeedImageDataLoader.Result
    
    public enum LoadError: Swift.Error {
        case failed
        case notFound
    }
    
    private final class LoadImageDataTask: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?
        
        init(completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            preventFurtherCompletions()
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
    }
    
    public func loadImageData(
        from url: URL,
        completion: @escaping (LoadResult) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        let task = LoadImageDataTask(completion: completion)
        
        store.retrieve(dataForURL: url) { [weak self] result in
            guard self != nil else { return }
            
            task.complete(with: result
                .mapError { _ in LoadError.failed }
                .flatMap { data in
                    data.map { .success($0) } ?? .failure(LoadError.notFound)
                })
        }
        return task
    }
}

// MARK: - Save

public extension LocalFeedImageDataLoader {
    typealias SaveResult = Result<Void, Swift.Error>
    
    enum SaveError: Swift.Error {
        case failed
    }
    
    func save(
        _ data: Data,
        for url: URL,
        completion: @escaping (SaveResult) -> Void
    ) {
        store.insert(data, for: url) { [weak self] result in
            guard self != nil else { return }
            
            completion(
                result
                    .mapError { _ in SaveError.failed }
            )
        }
    }
}