import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_cast

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: @escaping () -> FeedLoader.Publisher,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
    ) -> FeedViewController {
        let presentationAdapter = FeedPresentationAdapter(
            feedLoader: { feedLoader().dispatchOnMainQueue() }
        )
        let feedController = Self.makeFeedViewController(
            delegate: presentationAdapter,
            title: FeedPresenter.title
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: { imageLoader($0).dispatchOnMainQueue() }
        )
        let presenter = FeedPresenter(
            loadingView: WeakRefVirtualProxy(feedController),
            feedView: feedViewAdapter,
            errorView: WeakRefVirtualProxy(feedController)
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
