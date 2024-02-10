import EssentialFeed

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private struct Task: FeedImageDataLoaderTask {
        var callback: () -> Void
        
        func cancel() {
            callback()
        }
    }
    
    private(set) var cancelledURLs = [URL]()
    private var messages = [
        (url: URL, completion: (FeedImageDataLoader.Result) -> Void)
    ]()
    
    var loadedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> EssentialFeed.FeedImageDataLoaderTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with data: Data, at index: Int = 0) {
        messages[index].completion(.success(data))
    }
}
