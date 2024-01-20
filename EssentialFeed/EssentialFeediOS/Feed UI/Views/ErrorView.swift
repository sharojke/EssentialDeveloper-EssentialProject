import UIKit

public final class ErrorView: UIView {
    public var message: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    @IBOutlet private var label: UILabel!
    
    override public func awakeFromNib() {
        super.awakeFromNib()

        label.text = nil
    }
}
