@testable import EssentialFeed
@testable import EssentialFeediOS
import XCTest

// swiftlint:disable force_cast

final class ImageCommentsSnapshotTests: XCTestCase {
    func test_listWithComments() {
        let sut = makeSUT()
        
        sut.display(comments())
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "IMAGE_COMMENTS_light")
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "IMAGE_COMMENTS_dark")
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .light,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "IMAGE_COMMENTS_light_extraExtraExtraLarge"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .dark,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "IMAGE_COMMENTS_dark_extraExtraExtraLarge"
        )
    }
}

private extension ImageCommentsSnapshotTests {
    func makeSUT() -> ListViewController {
        let bundle = EssentialFeediOS.bundle
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func emptyComments() -> [CellController] {
        return []
    }
    
    func comments() -> [CellController] {
        return commentControllers().map { CellController(id: UUID(), $0) }
    }
    
    func commentControllers() -> [ImageCommentCellController] {
        return [
            ImageCommentCellController(
                model: ImageCommentViewModel(
                    // swiftlint:disable:next line_length
                    message: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                    date: "1000 years ago",
                    username: "a super-super long long long username"
                )
            ),
            ImageCommentCellController(
                model: ImageCommentViewModel(
                    message: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                    date: "4 min ago",
                    username: "a username"
                )
            ),
            ImageCommentCellController(
                model: ImageCommentViewModel(
                    message: "A short message",
                    date: "Yesterday",
                    username: "un"
                )
            )
        ]
    }
}

// swiftlint:enable force_cast
