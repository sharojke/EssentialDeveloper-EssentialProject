import UIKit

// swiftlint:disable force_unwrapping

func anyImageData() -> Data {
    return UIImage.make(withColor: .red).pngData()!
}

// swiftlint:enable force_unwrapping
