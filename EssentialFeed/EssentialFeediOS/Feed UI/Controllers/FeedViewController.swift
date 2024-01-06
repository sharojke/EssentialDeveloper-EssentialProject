import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var refreshController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
    private var tasks = [IndexPath: FeedImageDataLoaderTask]()
    
    private var tableModel = [FeedImage]() {
        didSet { tableView.reloadData() }
    }
    
    override public var refreshControl: UIRefreshControl? {
        get {
            return refreshController?.view
        }
        set {
            guard let newValue else { return }
            
            refreshController?.view = newValue
        }
    }
    
    public convenience init(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) {
        self.init()
        
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageLoader = imageLoader
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        refreshControl = refreshController?.view
        
        refreshController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }
        
        onViewIsAppearing = { viewController in
            viewController.refreshController?.refresh()
            viewController.onViewIsAppearing = nil
        }
    }
    
    override public func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    private func startTask(forRowAt indexPath: IndexPath) {
        // TODO: Start the task here when the implementation is clear
    }
    
    private func cancelTask(forRawAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let feedImageCell = FeedImageCell()
        feedImageCell.locationContainer.isHidden = cellModel.location == nil
        feedImageCell.descriptionLabel.text = cellModel.description
        feedImageCell.locationLabel.text = cellModel.location
        feedImageCell.feedImageView.image = nil
        feedImageCell.feedImageRetryButton.isHidden = true
        feedImageCell.feedImageContainer.startShimmering()
        
        let loadImage = { [weak self] in
            guard let self else { return }
            
            tasks[indexPath] = imageLoader?.loadImageData(from: cellModel.url) { [weak feedImageCell] result in
                let data = try? result.get()
                let image = data.flatMap(UIImage.init)
                feedImageCell?.feedImageView.image = image
                feedImageCell?.feedImageRetryButton.isHidden = image != nil
                feedImageCell?.feedImageContainer.stopShimmering()
            }
        }
        
        feedImageCell.onRetry = loadImage
        loadImage()
        
        return feedImageCell
    }
    
    override public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        startTask(forRowAt: indexPath)
    }
    
    override public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(forRawAt: indexPath)
    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { [weak self] indexPath in
            guard let self else { return }
            
            let cellModel = tableModel[indexPath.row]
            tasks[indexPath] = imageLoader?.loadImageData(
                from: cellModel.url,
                completion: { _ in }
            )
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { [weak self] indexPath in
            self?.cancelTask(forRawAt: indexPath)
        }
    }
}
