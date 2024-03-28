//import Combine
//import EssentialFeed
//import EssentialFeediOS
//import UIKit
//
//extension FeedUIIntegrationTests {
//    class LoaderSpy {
//        private var _feedRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
//        private var _cancelledImageURLs = [URL]()
//        private var _imageRequests = [URL]()
//        private var _imageResult: Result<Data, Error>?
//        private var _loadMoreRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
//    }
//}
//
//extension FeedUIIntegrationTests.LoaderSpy {
//    var feedRequests: [PassthroughSubject<Paginated<FeedImage>, Error>] {
//        return _feedRequests
//    }
//        
//    func loadPublisher() -> AnyPublisher<Paginated<FeedImage>, Error> {
//        let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
//        _feedRequests.append(publisher)
//        return publisher.eraseToAnyPublisher()
//    }
//    
//    func completeFeedLoading(
//        with feed: [FeedImage] = [],
//        at index: Int = 0
//    ) {
//        feedRequests[index].send(Paginated(items: feed, loadMorePublisher: { [weak self] in
//            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
//            self?._loadMoreRequests.append(publisher)
//            return publisher.eraseToAnyPublisher()
//        }))
//        feedRequests[index].send(completion: .finished)
//    }
//    
//    func completeFeedLoadingWithError(at index: Int = 0) {
//        feedRequests[index].send(completion: .failure(anyNSError()))
//    }
//}
//
//extension FeedUIIntegrationTests.LoaderSpy: FeedImageDataLoader {
//    var imageRequests: [URL] {
//        return _imageRequests
//    }
//    
//    var loadedImageURLs: [URL] {
//        return imageRequests
//    }
//    
//    var cancelledImageURLs: [URL] {
//        return _cancelledImageURLs
//    }
//    
//    func loadImageData(from url: URL) throws -> Data {
//        _imageRequests.append(url)
//        if let _imageResult {
//            return try _imageResult.get()
//        } else {
//            throw anyNSError()
//        }
//    }
//    
//    func cancelImageDataLoading(from url: URL) {
//        _cancelledImageURLs.append(url)
//    }
//    
//    func completeImageLoading(
//        with imageData: Data = anyImageData(),
//        at index: Int = 0
//    ) {
//        guard index < imageRequests.count else { return }
//        
//        _imageResult = .success(imageData)
//    }
//    
//    func completeImageLoadingWithError(at index: Int) {
//        _imageResult = .failure(anyNSError())
//    }
//}
//
//extension FeedUIIntegrationTests.LoaderSpy {
//    var loadMoreRequests: [PassthroughSubject<Paginated<FeedImage>, Error>] {
//        return _loadMoreRequests
//    }
//    
//    func completeLoadMore(
//        with feed: [FeedImage],
//        lastPage: Bool = false,
//        at index: Int = 0
//    ) {
//        loadMoreRequests[index].send(
//            Paginated(
//                items: feed,
//                loadMorePublisher: lastPage ? nil : { [weak self] in
//                    let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
//                    self?._loadMoreRequests.append(publisher)
//                    return publisher.eraseToAnyPublisher()
//                }
//            )
//        )
//    }
//    
//    func completeLoadMoreWithError(at index: Int) {
//        loadMoreRequests[index].send(completion: .failure(anyNSError()))
//    }
//}
