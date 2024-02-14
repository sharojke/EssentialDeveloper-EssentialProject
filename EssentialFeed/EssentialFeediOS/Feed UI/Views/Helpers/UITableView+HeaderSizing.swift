import UIKit

extension UITableView {
    func sizeTableHeaderToFit() {
        guard let header = tableHeaderView else { return }
        
        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let needsFrameUpdate = header.frame.height != size.height
        guard needsFrameUpdate else { return }
        
        header.frame.size.height = size.height
        tableHeaderView = header
    }
}
