import EssentialFeed
@testable import EssentialFeediOS
import UIKit

final class FeedViewAdapter: ResourceView {   
    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>
    
    private weak var controller: FeedViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    
    init(controller: FeedViewController?, loader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.display(viewModel.feed.map { feedImage in
            let adapter = ImageDataPresentationAdapter(
                loader: { [loader] in
                    loader(feedImage.url)
                }
            )
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(feedImage),
                delegate: adapter
            )
            
            adapter.presenter = LoadResourcePresenter(
                loadingView: WeakRefVirtualProxy(view),
                resourceView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: UIImage.tryMake
            )
            return view
        })
    }
}

private extension UIImage {
    struct InvalidImageData: Error {}

    static func tryMake(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw InvalidImageData()
        }
        return image
    }
}
