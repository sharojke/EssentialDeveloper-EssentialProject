import UIKit

extension UIRefreshControl {
    func update(isRefreshing: Bool) {
        if isRefreshing {
            beginRefreshing()
        } else {
            endRefreshing()
        }
    }
}
