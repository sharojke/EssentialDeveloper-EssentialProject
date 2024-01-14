import UIKit

extension UIImageView {
    func setImageAnimated(_ image: UIImage?) {
        self.image = image
        guard image != nil else { return }
        
        alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
}
