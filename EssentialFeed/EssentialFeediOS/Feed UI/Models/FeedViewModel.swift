import EssentialFeed
import Foundation

final class FeedViewModel {
    private let feedLoader: FeedLoader
    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?
    
    var isLoading = false {
        didSet { onChange?(self) }
    }
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.isLoading = false
        }
    }
}
