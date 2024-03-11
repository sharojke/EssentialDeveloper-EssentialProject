import UIKit

public final class ErrorView: UIButton {
    public var onHide: (() -> Void)?
    
    private var isVisible: Bool {
        return alpha > .zero
    }
    
    public var message: String? {
        get { return isVisible ? configuration?.title : nil }
        set { setMessageAnimated(newValue) }
    }
    
    private var titleAttributes: AttributeContainer {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        return AttributeContainer([
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: paragraphStyle
        ])
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    private func configure() {
        var configuration = Configuration.plain()
        configuration.titlePadding = .zero
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = .errorBackgroundColor
        configuration.background.cornerRadius = .zero
        self.configuration = configuration
        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        hideMessage()
    }
    
    private func setMessageAnimated(_ message: String?) {
        if let message {
            showAnimated(message)
        } else {
            hideMessageAnimated()
        }
    }

    private func showAnimated(_ message: String) {
        configuration?.attributedTitle = AttributedString(message, attributes: titleAttributes)
        let inset: CGFloat = 8
        configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset
        )
        
        UIView.animate(withDuration: .transitionDuration) {
            self.alpha = 1
        }
    }
    
    @objc 
    private func hideMessageAnimated() {
        UIView.animate(
            withDuration: .transitionDuration,
            animations: { self.alpha = .zero },
            completion: { completed in
                if completed {
                    self.hideMessage()
                }
            }
        )
    }
    
    private func hideMessage() {
        configuration?.attributedTitle = nil
        configuration?.contentInsets = .zero
        alpha = .zero
        onHide?()
    }
}

extension UIColor {
    static var errorBackgroundColor: Self {
        let red = 0.99951404330000004
        let green = 0.41759261489999999
        let blue = 0.4154433012
        return Self(red: red, green: green, blue: blue, alpha: 1)
    }
}

extension TimeInterval {
    static let transitionDuration: Self = 0.25
}
