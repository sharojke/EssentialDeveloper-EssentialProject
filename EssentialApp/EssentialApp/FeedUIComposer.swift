import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_cast

public enum FeedUIComposer {
    private typealias FeedPresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>
    
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
    ) -> ListViewController {
        let presentationAdapter = FeedPresentationAdapter(loader: feedLoader)
        let feedController = Self.makeFeedViewController(
            delegate: presentationAdapter,
            title: FeedPresenter.title
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: imageLoader
        )
        let presenter = LoadResourcePresenter(
            loadingView: WeakRefVirtualProxy(feedController),
            resourceView: feedViewAdapter,
            errorView: WeakRefVirtualProxy(feedController), 
            mapper: FeedPresenter.map
        )
        presentationAdapter.presenter = presenter
        return feedController
    }
}

// MARK: - Helpers

private extension FeedUIComposer {
    static func makeFeedViewController(
        delegate: FeedViewControllerDelegate,
        title: String
    ) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController()
        let feedController = viewController as! ListViewController
        feedController.delegate = delegate
        feedController.title = title
        return feedController
    }
}

// swiftlint:enable force_cast
