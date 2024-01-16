import EssentialFeed
import UIKit

final class FeedViewAdapter: FeedView {
    typealias WeakCellController = WeakRefVirtualProxy<FeedImageCellController>
    typealias PresentationAdapter = FeedImageDataLoaderPresentationAdapter<WeakCellController, UIImage>
    
    private weak var controller: FeedViewController?
    private let loader: FeedImageDataLoader
    
    init(controller: FeedViewController?, loader: FeedImageDataLoader) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { feedImage in
            let adapter = PresentationAdapter(
                model: feedImage,
                imageLoader: loader
            )
            let view = FeedImageCellController(delegate: adapter)

            adapter.presenter = FeedImagePresenter(
                view: WeakRefVirtualProxy(view),
                imageTransformer: UIImage.init
            )

            return view
        }
    }
}
