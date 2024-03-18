@testable import EssentialFeed
@testable import EssentialFeediOS
import XCTest

// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

private final class ImageStub: FeedImageCellControllerDelegate {
    let viewModel: FeedImageViewModel
    let image: UIImage?
    weak var controller: FeedImageCellController?
    
    init(
        description: String?,
        location: String?,
        image: UIImage?
    ) {
        self.viewModel = FeedImageViewModel(
            description: description,
            location: location
        )
        self.image = image
    }
    
    func didRequestImage() {
        controller?.display(ResourceLoadingViewModel(isLoading: false))
        
        if let image {
            controller?.display(image)
            controller?.display(ResourceErrorViewModel(message: .none))
        } else {
            controller?.display(ResourceErrorViewModel(message: "any"))
        }
    }
    
    func didCancelImageRequest() {
    }
}

final class FeedSnapshotTests: XCTestCase {
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "FEED_WITH_CONTENT_dark")
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .light,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_CONTENT_light_extraExtraExtraLarge"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .dark,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_CONTENT_dark_extraExtraExtraLarge"
        )
    }
    
    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()
        
        sut.display(feedWithFailedImageLoading())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .light)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .dark)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_dark"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .light,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_light_extraExtraExtraLarge"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .dark,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_dark_extraExtraExtraLarge"
        )
    }
    
    func test_feedWithLoadMoreIndicator() {
        let sut = makeSUT()
        
        sut.display(feedWithLoadMoreIndicator())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .light)),
            named: "FEED_WITH_LOAD_MORE_INDICATOR_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .dark)),
            named: "FEED_WITH_LOAD_MORE_INDICATOR_dark"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .light,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_LOAD_MORE_INDICATOR_light_extraExtraExtraLarge"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .dark,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_LOAD_MORE_INDICATOR_dark_extraExtraExtraLarge"
        )
    }
    
    func test_feedWithLoadMoreError() {
        let sut = makeSUT()
        
        sut.display(feedWithLoadMoreError())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .light)),
            named: "FEED_WITH_LOAD_MORE_ERROR_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone(style: .dark)),
            named: "FEED_WITH_LOAD_MORE_ERROR_dark"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .light,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_LOAD_MORE_ERROR_light_extraExtraExtraLarge"
        )
        assert(
            snapshot: sut.snapshot(
                for: .iPhone(
                    style: .dark,
                    contentSize: .extraExtraExtraLarge
                )
            ),
            named: "FEED_WITH_LOAD_MORE_ERROR_dark_extraExtraExtraLarge"
        )
    }
}

private extension FeedSnapshotTests {
    func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func emptyFeed() -> [FeedImageCellController] {
        return []
    }
    
    func feedWithContent() -> [ImageStub] {
        return [
            ImageStub(
                // swiftlint:disable:next line_length
                description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                location: "East Side Gallery\nMemorial in Berlin, Germany",
                image: UIImage.make(withColor: .red)
            ),
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: UIImage.make(withColor: .green)
            )
        ]
    }
    
    func feedWithFailedImageLoading() -> [ImageStub] {
        return [
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: nil
            ),
            ImageStub(
                description: nil,
                location: "At home",
                image: nil
            )
        ]
    }
    
    private func feedWithLoadMoreIndicator() -> [CellController] {
        let loadMore = LoadMoreCellController()
        loadMore.display(ResourceLoadingViewModel(isLoading: true))
        return feedWith(loadMore: loadMore)
    }
    
    private func feedWithLoadMoreError() -> [CellController] {
        let loadMore = LoadMoreCellController()
        let errorViewModel = ResourceErrorViewModel(message: "This is a multiline\nerror message")
        loadMore.display(errorViewModel)
        return feedWith(loadMore: loadMore)
    }
    
    private func feedWith(loadMore: LoadMoreCellController) -> [CellController] {
        let stub = feedWithContent().last!
        let cellController = FeedImageCellController(
            viewModel: stub.viewModel,
            delegate: stub,
            selection: {}
        )
        stub.controller = cellController
        return [
            CellController(id: UUID(), cellController),
            CellController(id: UUID(), loadMore)
        ]
    }
}

private extension ListViewController {
    func display(_ stubs: [ImageStub]) {
        let cells = stubs.map { stub in
            let cellController = FeedImageCellController(
                viewModel: stub.viewModel,
                delegate: stub, 
                selection: {}
            )
            stub.controller = cellController
            return CellController(id: UUID(), cellController)
        }
        display(cells)
    }
}

// swiftlint:enable force_cast
// swiftlint:enable force_unwrapping
