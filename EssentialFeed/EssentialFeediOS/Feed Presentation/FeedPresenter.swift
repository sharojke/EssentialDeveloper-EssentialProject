import EssentialFeed
import Foundation

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

public final class FeedPresenter {
    static var title: String {
        return NSLocalizedString(
            "My Feed",
            bundle: Bundle(for: Self.self),
            comment: "Title for the feed view"
        )
    }
    
    private let loadingView: FeedLoadingView
    private let feedView: FeedView
    private let errorView: FeedErrorView
    
    init(
        loadingView: FeedLoadingView,
        feedView: FeedView,
        errorView: FeedErrorView
    ) {
        self.loadingView = loadingView
        self.feedView = feedView
        self.errorView = errorView
    }
    
    func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
