import EssentialFeed
import UIKit

final class FeedRefreshViewController: NSObject {
    private let feedLoader: FeedLoader
    var onRefresh: (([FeedImage]) -> Void)?
    
    lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(
            self,
            action: #selector(refresh),
            for: .valueChanged
        )
        return view
    }()
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    @objc
    func refresh() {
        view.beginRefreshing()
        
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onRefresh?(feed)
            }
            
            self?.view.endRefreshing()
        }
    }
}
