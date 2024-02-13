import UIKit

extension UITableViewController {
    private final class FakeRefreshControl: UIRefreshControl {
        private var _isRefreshing = false
        
        override var isRefreshing: Bool { _isRefreshing }
        
        override func beginRefreshing() {
            _isRefreshing = true
        }
        
        override func endRefreshing() {
            _isRefreshing = false
        }
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            prepareForFirstAppearance()
        }
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    private func prepareForFirstAppearance() {
        setSmallFrameToPreventRenderingCells()
        replaceRefreshControlWithFakeForiOS17PlusSupport()
    }
    
    private func setSmallFrameToPreventRenderingCells() {
        tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
    }
    
    private func replaceRefreshControlWithFakeForiOS17PlusSupport() {
        let fake = FakeRefreshControl()
        
        refreshControl?.allTargets.forEach { [weak self] target in
            self?.refreshControl?.actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?
                .forEach { action in
                    fake.addTarget(
                        target,
                        action: Selector(action),
                        for: .valueChanged
                    )
                }
        }
        
        refreshControl = fake
    }
}

extension UIControl {
    func simulate(event: UIControl.Event) {
        allTargets.forEach { [weak self] target in
            self?.actions(
                forTarget: target,
                forControlEvent: event
            )?
                .forEach { action in
                    (target as NSObject).perform(Selector(action))
                }
        }
    }
}

extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(event: .valueChanged)
    }
}

extension UIButton {
    func simulateTap() {
        simulate(event: .touchUpInside)
    }
}
