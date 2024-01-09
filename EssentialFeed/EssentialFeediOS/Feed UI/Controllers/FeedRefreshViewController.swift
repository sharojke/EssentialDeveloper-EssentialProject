import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let presenter: FeedPresenter
    lazy var view = loadView()
    
    init(presenter: FeedPresenter) {
        self.presenter = presenter
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
    
    func display(isLoading: Bool) {
        if isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
    
    @objc
    func refresh() {
        presenter.loadFeed()
    }
}
