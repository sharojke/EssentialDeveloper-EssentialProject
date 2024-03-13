import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_cast

public enum CommentsUIComposer {
    private typealias FeedPresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>
    
    public static func commentsComposedWith(
        commentsLoader: @escaping () -> AnyPublisher<[FeedImage], Error>
    ) -> ListViewController {
        let presentationAdapter = FeedPresentationAdapter(loader: commentsLoader)
        let feedController = makeFeedViewController(title: FeedPresenter.title)
        feedController.onRefresh = presentationAdapter.loadResource
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: { _ in Empty<Data, Error>().eraseToAnyPublisher() }
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

private extension CommentsUIComposer {
    static func makeFeedViewController(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController()
        let feedController = viewController as! ListViewController
        feedController.title = title
        return feedController
    }
}

// swiftlint:enable force_cast
