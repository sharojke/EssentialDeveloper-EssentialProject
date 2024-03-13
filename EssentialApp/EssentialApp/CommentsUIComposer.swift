import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_cast

final class CommentsViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    
    init(controller: ListViewController?) {
        self.controller = controller
    }
    
    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.display(viewModel.comments.map { viewModel in
            CellController(
                id: viewModel,
                ImageCommentCellController(model: viewModel)
            )
        })
    }
}

public enum CommentsUIComposer {
    private typealias CommentsPresentationAdapter = LoadResourcePresentationAdapter<[ImageComment], CommentsViewAdapter>
    
    public static func commentsComposedWith(
        commentsLoader: @escaping () -> AnyPublisher<[ImageComment], Error>
    ) -> ListViewController {
        let presentationAdapter = CommentsPresentationAdapter(loader: commentsLoader)
        let commentsController = makeCommentsViewController(title: ImageCommentsPresenter.title)
        commentsController.onRefresh = presentationAdapter.loadResource
        let commentsViewAdapter = CommentsViewAdapter(controller: commentsController)
        let presenter = LoadResourcePresenter(
            loadingView: WeakRefVirtualProxy(commentsController),
            resourceView: commentsViewAdapter,
            errorView: WeakRefVirtualProxy(commentsController),
            mapper: { ImageCommentsPresenter.map($0) }
        )
        presentationAdapter.presenter = presenter
        return commentsController
    }
}

// MARK: - Helpers

private extension CommentsUIComposer {
    static func makeCommentsViewController(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let storyboardViewController = storyboard.instantiateInitialViewController()
        let controller = storyboardViewController as! ListViewController
        controller.title = title
        return controller
    }
}

// swiftlint:enable force_cast
