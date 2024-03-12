@testable import EssentialFeed
@testable import EssentialFeediOS
import XCTest

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
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .light,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "LIST_WITH_ERROR_MESSAGE_light_extraExtraExtraLarge"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .dark,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "LIST_WITH_ERROR_MESSAGE_dark_extraExtraExtraLarge"
        )
    }
}

private extension ListSnapshotTests {
    func makeSUT() -> ListViewController {
        let controller = ListViewController()
        controller.loadViewIfNeeded()
        controller.tableView.separatorStyle = .none
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func emptyList() -> [CellController] {
        return []
    }
}
