import EssentialFeed
import UIKit

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let loader: FeedImageDataLoader
    
    init(controller: FeedViewController?, loader: FeedImageDataLoader) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { feedImage in
            let viewModel = FeedImageViewModel(
                model: feedImage,
                imageLoader: loader,
                imageTransformer: UIImage.init
            )
            return FeedImageCellController(viewModel: viewModel)
        }
    }
}

private final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(object: T) {
        self.object = object
    }
}

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let feedPresenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(loadFeed: feedPresenter.loadFeed)
        let feedController = FeedViewController(refreshController: refreshController)
        feedPresenter.loadingView = WeakRefVirtualProxy(object: refreshController)
        feedPresenter.feedView = FeedViewAdapter(
            controller: feedController,
            loader: imageLoader
        )
        return feedController
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}
