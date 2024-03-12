import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

extension FeedUIIntegrationTests {
    class LoaderSpy {
        private var _feedRequests = [PassthroughSubject<[FeedImage], Error>]()
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

extension FeedUIIntegrationTests.LoaderSpy {
    var feedRequests: [PassthroughSubject<[FeedImage], Error>] {
        return _feedRequests
    }
        
    func loadPublisher() -> AnyPublisher<[FeedImage], Error> {
        let publisher = PassthroughSubject<[FeedImage], Error>()
        _feedRequests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeFeedLoading(
        with feed: [FeedImage] = [],
        at index: Int = 0
    ) {
        feedRequests[index].send(feed)
    }
    
    func completeFeedLoadingWithError(at index: Int = 0) {
        feedRequests[index].send(completion: .failure(anyNSError()))
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
        with imageData: Data = anyImageData(),
        at index: Int = 0
    ) {
        guard index < imageRequests.count else { return }
        
        imageRequests[index].completion(.success(imageData))
    }
    
    func completeImageLoadingWithError(at index: Int) {
        imageRequests[index].completion(.failure(anyNSError()))
    }
}
