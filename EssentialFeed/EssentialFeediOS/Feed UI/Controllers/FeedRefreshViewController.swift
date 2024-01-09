import UIKit

// swiftlint:disable weak_delegate

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let delegate: FeedRefreshViewControllerDelegate
    lazy var view = loadView()
    
    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
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
        delegate.didRequestFeedRefresh()
    }
}

// swiftlint:enable weak_delegate
