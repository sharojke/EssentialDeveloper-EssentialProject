import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let loadFeed: () -> Void
    lazy var view = loadView()
    
    init(loadFeed: @escaping () -> Void) {
        self.loadFeed = loadFeed
    }
    
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(
            self,
            action: #selector(refresh),
            for: .valueChanged
        )
        return view
    }
    
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
    
    @objc
    func refresh() {
        loadFeed()
    }
}
