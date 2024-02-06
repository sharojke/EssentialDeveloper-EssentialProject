import EssentialFeed

public final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    private let primaryLoader: FeedImageDataLoader
    private let fallbackLoader: FeedImageDataLoader
    
    public init(primaryLoader: FeedImageDataLoader, fallbackLoader: FeedImageDataLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }
    
    public func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        let task = Task()
        task.wrapped = primaryLoader.loadImageData(from: url) { [weak self] receivedResult in
            switch receivedResult {
            case .success:
                completion(receivedResult)
                
            case .failure:
                task.wrapped = self?.fallbackLoader.loadImageData(from: url, completion: completion)
            }
        }
        
        return task
    }
}
