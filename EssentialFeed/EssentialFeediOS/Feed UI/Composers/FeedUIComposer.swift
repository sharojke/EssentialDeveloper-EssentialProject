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

private final class FeedPresentationAdapter: FeedRefreshViewControllerDelegate {
    let feedLoader: FeedLoader
    let presenter: FeedPresenter
    
    init(feedLoader: FeedLoader, presenter: FeedPresenter) {
        self.feedLoader = feedLoader
        self.presenter = presenter
    }
    
    func didRequestFeedRefresh() {
        presenter.didStartLoadingFeed()
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.presenter.didFinishLoadingFeed(with: feed)
                
            case .failure(let error):
                self?.presenter.didFinishLoadingFeed(with: error)
            }
        }
    }
}

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let presenter = FeedPresenter()
        let presentationAdapter = FeedPresentationAdapter(
            feedLoader: feedLoader,
            presenter: presenter
        )
        let refreshController = FeedRefreshViewController(delegate: presentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        presenter.loadingView = WeakRefVirtualProxy(object: refreshController)
        presenter.feedView = FeedViewAdapter(
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
