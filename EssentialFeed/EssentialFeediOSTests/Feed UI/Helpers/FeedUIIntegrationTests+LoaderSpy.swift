import EssentialFeed
import EssentialFeediOS
import UIKit

extension FeedUIIntegrationTests {
    class LoaderSpy {
        private var _feedRequests = [(FeedLoader.Result) -> Void]()
        private var _cancelledImageURLs = [URL]()
        private var _imageRequests = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
    }
}

extension FeedUIIntegrationTests.LoaderSpy {
    struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallBack: () -> Void
        
        func cancel() {
            cancelCallBack()
        }
    }
}

extension FeedUIIntegrationTests.LoaderSpy: FeedLoader {
    var feedRequests: [(FeedLoader.Result) -> Void] {
        return _feedRequests
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        _feedRequests.append(completion)
    }
    
    func completeFeedLoading(
        with feed: [FeedImage] = [],
        at index: Int = 0
    ) {
        feedRequests[index](.success(feed))
    }
    
    func completeFeedLoadingWithError(at index: Int = 0) {
        feedRequests[index](.failure(anyNSError()))
    }
}

extension FeedUIIntegrationTests.LoaderSpy: FeedImageDataLoader {
    var imageRequests: [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)] {
        return _imageRequests
    }
    
    var loadedImageURLs: [URL] {
        return imageRequests.map { $0.url }
    }
    
    var cancelledImageURLs: [URL] {
        return _cancelledImageURLs
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        _imageRequests.append((url, completion))
        return TaskSpy { [weak self] in
            self?.cancelImageDataLoading(from: url)
        }
    }
    
    func cancelImageDataLoading(from url: URL) {
        _cancelledImageURLs.append(url)
    }
    
    func completeImageLoading(
        with imageData: Data = Data(),
        at index: Int = 0
    ) {
        imageRequests[index].completion(.success(imageData))
    }
    
    func completeImageLoadingWithError(at index: Int) {
        imageRequests[index].completion(.failure(anyNSError()))
    }
}
