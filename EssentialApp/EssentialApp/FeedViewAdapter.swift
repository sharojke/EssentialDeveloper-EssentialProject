import EssentialFeed
import EssentialFeediOS
import UIKit

private struct InvalidImageData: Error {}

final class FeedViewAdapter: ResourceView {
    typealias WeakCellController = WeakRefVirtualProxy<FeedImageCellController>
    typealias PresentationAdapter = FeedImageDataLoaderPresentationAdapter<WeakCellController, UIImage>
    
    private weak var controller: FeedViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    
    init(controller: FeedViewController?, loader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.display(viewModel.feed.map { feedImage in
            let adapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>(
                loader: { [loader] in
                    loader(feedImage.url)
                }
            )
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter<FeedImageCellController, UIImage>.map(feedImage),
                delegate: adapter
            )
            
            adapter.presenter = LoadResourcePresenter(
                loadingView: WeakRefVirtualProxy(view),
                resourceView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: { data in
                    guard let image = UIImage(data: data) else {
                        throw InvalidImageData()
                    }
                    return image
                }
            )
            return view
        })
    }
}
