import EssentialFeed
import XCTest

private final class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

extension FeedUIIntegrationTests {
    var loadError: String {
        return LoadResourcePresenter<Any, DummyView>.loadError
    }
    
    var feedTitle: String {
        return FeedPresenter.title
    }
    
    var commentsTitle: String {
        return ImageCommentsPresenter.title
    }
}
