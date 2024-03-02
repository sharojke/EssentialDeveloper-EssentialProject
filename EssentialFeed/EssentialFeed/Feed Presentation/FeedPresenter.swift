import Foundation

public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

public protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

public final class FeedPresenter {
    public static var title: String {
        return NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't load the image feed from the server"
        )
    }
    
    private let loadingView: ResourceLoadingView
    private let feedView: FeedView
    private let errorView: FeedErrorView
    
    private var feedLoadError: String {
        return NSLocalizedString(
            "GENERIC_CONNECTION_ERROR",
            tableName: "Shared",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't load the image feed from the server"
        )
    }
    
    public init(
        loadingView: ResourceLoadingView,
        feedView: FeedView,
        errorView: FeedErrorView
    ) {
        self.loadingView = loadingView
        self.feedView = feedView
        self.errorView = errorView
    }
    
    public func didStartLoadingFeed() {
        errorView.display(.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }
    
    public func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
    
    public func didFinishLoadingFeed(with error: Error) {
        errorView.display(.error(message: feedLoadError))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
}
