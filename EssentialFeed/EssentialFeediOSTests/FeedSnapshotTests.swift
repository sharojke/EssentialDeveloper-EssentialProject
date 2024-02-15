@testable import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_cast

private final class ImageStub: FeedImageCellControllerDelegate {
    let viewModel: FeedImageViewModel<UIImage>
    weak var controller: FeedImageCellController?
    
    init(
        description: String?,
        location: String?,
        image: UIImage?,
        controller: FeedImageCellController? = nil
    ) {
        self.viewModel = FeedImageViewModel(
            description: description,
            location: location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil
        )
        self.controller = controller
    }
    
    func didRequestImage() {
        controller?.display(viewModel)
    }
    
    func didCancelImageRequest() {
    }
}

final class FeedSnapshotTests: XCTestCase {
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        assert(snapshot: sut.snapshot(), named: "EMPTY_FEED")
    }
    
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        assert(snapshot: sut.snapshot(), named: "EMPTY_WITH_CONTENT")
    }
    
    func test_feedWithErrorMessage() {
        let sut = makeSUT()
        
        sut.display(.error(message: "this is a\nmulti-line\nerror message"))
        
        assert(snapshot: sut.snapshot(), named: "FEED_WITH_ERROR_MESSAGE")
    }
    
    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()
        
        sut.display(feedWithFailedImageLoading())
        
        assert(snapshot: sut.snapshot(), named: "FEED_WITH_FAILED_IMAGE_LOADING")
    }
}

private extension FeedSnapshotTests {
    func makeSUT() -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! FeedViewController
        controller.loadViewIfNeeded()
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
    
    func record(
        snapshot: UIImage,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try snapshotData?.write(to: snapshotURL)
        } catch {
            XCTFail(
                "Failed to record a snapshot with an error \(error)",
                file: file,
                line: line
            )
        }
    }
    
    func assert(
        snapshot: UIImage,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            XCTFail(
                "Failed to load stored snapshot at URL \(snapshotURL). Use the record method to store the snapshot before asserting",
                file: file,
                line: line
            )
            return
        }
        guard storedSnapshotData != snapshotData else { return }
        
        let temporarySnapshotURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).appendingPathComponent(snapshotURL.lastPathComponent)
        try? snapshotData?.write(to: temporarySnapshotURL)
        
        XCTFail(
            "New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL). Stored snapshot URL: \(snapshotURL)",
            file: file,
            line: line
        )
    }
    
    func makeSnapshotData(
        for snapshot: UIImage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Data? {
        guard let data = snapshot.pngData() else {
            XCTFail(
                "Expected to generate PNG data representation form snapshot",
                file: file,
                line: line
            )
            return nil
        }
        
        return data
    }
    
    func makeSnapshotURL(named name: String, file: StaticString) -> URL {
        let snapshotsFolderURL = URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots", isDirectory: true)
        return snapshotsFolderURL
            .appendingPathComponent("\(name).png")
    }
}

private extension UIViewController {
    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { action in
            view.layer.render(in: action.cgContext)
        }
    }
}

private extension FeedViewController {
    func display(_ stubs: [ImageStub]) {
        let cells = stubs.map { stub in
            let cellController = FeedImageCellController(delegate: stub)
            stub.controller = cellController
            return cellController
        }
        display(cells)
    }
}

// swiftlint:enable force_cast
