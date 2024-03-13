import EssentialFeed
import UIKit

// swiftlint:disable force_unwrapping

private final class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

var loadError: String {
    return LoadResourcePresenter<Any, DummyView>.loadError
}

var feedTitle: String {
    return FeedPresenter.title
}

var commentsTitle: String {
    return ImageCommentsPresenter.title
}

func anyImageData() -> Data {
    return UIImage.make(withColor: .red).pngData()!
}

// swiftlint:enable force_unwrapping
