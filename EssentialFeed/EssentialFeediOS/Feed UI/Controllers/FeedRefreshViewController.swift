import UIKit

final class FeedRefreshViewController: NSObject {
    private let viewModel: FeedViewModel
    lazy var view = binded(UIRefreshControl())
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    @objc
    func refresh() {
        viewModel.loadFeed()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingStateChange = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        
        view.addTarget(
            self,
            action: #selector(refresh),
            for: .valueChanged
        )
        
        return view
    }
}
