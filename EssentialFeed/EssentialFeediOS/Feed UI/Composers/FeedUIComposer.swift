import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = { [weak feedController] feed in
            feedController?.tableModel = feed.map { feedImage in
                FeedImageCellController(
                    model: feedImage,
                    imageLoader: imageLoader
                )
            }
        }
        return feedController
    }
}
