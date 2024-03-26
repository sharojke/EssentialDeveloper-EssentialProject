import EssentialFeed
@testable import EssentialFeediOS
import UIKit

final class FeedViewAdapter: ResourceView {   
    private typealias ImageDataPresentationAdapter = 
    LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>
    
    private typealias LoadMorePresentationAdapter =
    LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>
    
    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    private let selection: (FeedImage) -> Void
    private let currentFeed: [FeedImage: CellController]
    
    init(
        controller: ListViewController,
        loader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void,
        currentFeed: [FeedImage: CellController] = [:]
    ) {
        self.currentFeed = currentFeed
        self.controller = controller
        self.loader = loader
        self.selection = selection
    }
    
    func display(_ viewModel: Paginated<FeedImage>) {
        guard let controller else { return }
        
        var currentFeed = self.currentFeed
        
        let feed = viewModel.items.map { feedImage in
            if let controller = currentFeed[feedImage] {
                return controller
            }
            
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
            let controller = CellController(id: feedImage, view)
            currentFeed[feedImage] = controller
            return controller
        }
        
        if let loadMorePublisher = viewModel.loadMorePublisher {
            let loadMoreAdapter = LoadMorePresentationAdapter(loader: loadMorePublisher)
            let loadMoreCellController = LoadMoreCellController(callback: loadMoreAdapter.loadResource)
            
            loadMoreAdapter.presenter = LoadResourcePresenter(
                loadingView: WeakRefVirtualProxy(loadMoreCellController),
                resourceView: FeedViewAdapter(
                    controller: controller,
                    loader: loader,
                    selection: selection,
                    currentFeed: currentFeed
                ),
                errorView: WeakRefVirtualProxy(loadMoreCellController),
                mapper: { $0 }
            )
            
            let loadMoreSection = [CellController(id: UUID(), loadMoreCellController)]
            controller.display(feed, loadMoreSection)
        } else {
            controller.display(feed)
        }
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
