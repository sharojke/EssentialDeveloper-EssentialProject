import UIKit

extension UIView {
    func enforceLayoutCycle() {
        layoutIfNeeded()
        executeRunLoopToCleanUpReferences()
    }
}
