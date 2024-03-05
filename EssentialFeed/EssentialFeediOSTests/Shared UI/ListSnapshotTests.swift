@testable import EssentialFeed
@testable import EssentialFeediOS
import XCTest

// swiftlint:disable force_cast

final class ListSnapshotTests: XCTestCase {
    func test_emptyList() {
        let sut = makeSUT()
        
        sut.display(emptyList())
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "EMPTY_LIST_light")
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "EMPTY_LIST_dark")
    }
    
    func test_listWithErrorMessage() {
        let sut = makeSUT()
        
        sut.display(.error(message: "this is a\nmulti-line\nerror message"))
        
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .light)),
            named: "LIST_WITH_ERROR_MESSAGE_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .dark)),
            named: "LIST_WITH_ERROR_MESSAGE_dark"
        )
    }
}

private extension ListSnapshotTests {
    func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func emptyList() -> [CellController] {
        return []
    }
}

// swiftlint:enable force_cast
