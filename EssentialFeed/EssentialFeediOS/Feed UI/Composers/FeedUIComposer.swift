import EssentialFeed
import UIKit

// swiftlint:disable force_cast

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let feedLoader = MainQueueDispatchDecorator(
            decoratee: feedLoader
        )
        let presentationAdapter = FeedPresentationAdapter(
            feedLoader: feedLoader
        )
        let feedController = FeedViewController.makeWith(
            delegate: presentationAdapter,
            title: FeedPresenter.title
        )
        let imageLoader = MainQueueDispatchDecorator(
            decoratee: imageLoader
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: imageLoader
        )
        let presenter = FeedPresenter(
            loadingView: WeakRefVirtualProxy(feedController),
            feedView: feedViewAdapter
        )
        presentationAdapter.presenter = presenter
        return feedController
    }
}

private extension FeedViewController {
    static func makeWith(
        delegate: FeedViewControllerDelegate,
        title: String
    ) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController()
        let feedController = viewController as! FeedViewController
        feedController.delegate = delegate
        feedController.title = title
        return feedController
    }
}

// swiftlint:enable force_cast
