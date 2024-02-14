import EssentialFeediOS
import XCTest

// swiftlint:disable force_cast

final class FeedSnapshotTests: XCTestCase {
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        record(snapshot: sut.snapshot(), named: "EMPTY_FEED")
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
    
    func record(
        snapshot: UIImage,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail(
                "Expected to generate PNG data representation form snapshot",
                file: file,
                line: line
            )
            return
        }
        
        let snapshotsFolderURL = URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotsFolderURL,
                withIntermediateDirectories: true
            )
            try snapshotData.write(to: snapshotsFolderURL
                .appendingPathComponent("\(name).png"))
        } catch {
            XCTFail(
                "Failed to record a snapshot with an error \(error)",
                file: file,
                line: line
            )
        }
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

// swiftlint:enable force_cast
