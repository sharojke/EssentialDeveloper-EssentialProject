import EssentialFeed
@testable import EssentialFeediOS
import UIKit

final class FeedViewAdapter: ResourceView {   
    private typealias ImageDataPresentationAdapter = 
    LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>
    
    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    private let selection: (FeedImage) -> Void
    
    init(
        controller: ListViewController?,
        loader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void
    ) {
        self.controller = controller
        self.loader = loader
        self.selection = selection
    }
    
    func display(_ viewModel: Paginated<FeedImage>) {
        let feed = viewModel.items.map { feedImage in
            let adapter = ImageDataPresentationAdapter(
                loader: { [loader] in
                    loader(feedImage.url)
                }
            )
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(feedImage),
                delegate: adapter
            ) { [selection] in
                selection(feedImage)
            }
            
            adapter.presenter = LoadResourcePresenter(
                loadingView: WeakRefVirtualProxy(view),
                resourceView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: UIImage.tryMake
            )
            return CellController(id: feedImage, view)
        }
        
        let loadMoreCellController = LoadMoreCellController {
            viewModel.loadMore? { _ in }
        }
        let loadMoreSection = [CellController(id: UUID(), loadMoreCellController)]
        
        controller?.display(feed, loadMoreSection)
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
