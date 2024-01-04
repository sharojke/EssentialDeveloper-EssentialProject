import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

private final class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_loadFeedActions_requestsFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertTrue(loader.feedRequests.isEmpty)
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(
            loader.feedRequests.count,
            0,
            "Expected no loading requests before view is loaded"
        )
        
        sut.simulateAppearance()
        XCTAssertEqual(
            loader.feedRequests.count,
            1,
            "Expected a loading requests once view is loaded"
        )
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(
            loader.feedRequests.count,
            2,
            "Expected another loading request once the the user initiates a load"
        )
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(
            loader.feedRequests.count,
            3,
            "Expected another loading request once the the user initiates another load"
        )
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(
            sut.isShowingReloadingIndicator,
            "Expected the loading indicator once the view is loaded"
        )
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(
            sut.isShowingReloadingIndicator,
            "Expected no loading indicator once the the loading is completed successfully"
        )
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(
            sut.isShowingReloadingIndicator,
            "Expected the loading indicator once the user initiates a reload"
        )
        
        loader.completeFeedLoadingWithError(at: 1)
        XCTAssertFalse(
            sut.isShowingReloadingIndicator,
            "Expected no loading indicator once the the loading is completed with error"
        )
        
        sut.simulateAppearance()
        XCTAssertFalse(
            sut.isShowingReloadingIndicator,
            "Expected no loading indicator after the view is loaded once"
        )
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage(
            description: "a description",
            location: "a location"
        )
        let image1 = makeImage(
            location: "a location"
        )
        let image2 = makeImage(
            description: "a description"
        )
        let image3 = makeImage()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0])
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3])
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage(
            description: "a description",
            location: "a location"
        )
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0])
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage()
        let image1 = makeImage()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        XCTAssertEqual(
            loader.loadedImageURLs,
            [],
            "Expected no image URL requests until views become visible"
        )
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url],
            "Expected first image URL request once first view becomes visible"
        )
        
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected second image URL request once second view becomes visible"
        )
    }
}

// MARK: - Helpers

private extension FeedViewControllerTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: FeedViewController,
        loader: LoaderSpy
    ) {
        let loader = LoaderSpy()
        let sut = FeedViewController(
            feedLoader: loader,
            imageLoader: loader
        )
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    func makeImage(
        url: URL = anyURL(),
        description: String? = nil,
        location: String? = nil
    ) -> FeedImage {
        return FeedImage(
            id: UUID(),
            url: anyURL(),
            description: description,
            location: location
        )
    }
    
    func assertThat(
        _ sut: FeedViewController,
        isRendering feed: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard sut.numberOfRenderedFeedImageViews == feed.count else {
            return XCTFail(
                "Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews) instead",
                file: file,
                line: line
            )
        }
        
        feed.enumerated().forEach { index, image in
            assertThat(
                sut,
                hasViewConfiguredFor: image,
                at: index,
                file: file,
                line: line
            )
        }
    }
    
    func assertThat(
        _ sut: FeedViewController,
        hasViewConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = sut.feedImageView(at: index)
        guard let cell = view as? FeedImageCell else {
            return XCTFail(
                "Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead",
                file: file,
                line: line
            )
        }
        
        let shouldLocationBeVisible = image.location != nil
        XCTAssertEqual(
            cell.isShowingLocation,
            shouldLocationBeVisible,
            "Expected `isShowingLocation` to be \(shouldLocationBeVisible) at index \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.descriptionText,
            image.description,
            "Expected `descriptionText` to be \(String(describing: image.description)) at index \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.locationText,
            image.location,
            "Expected `locationText` to be \(String(describing: image.location)) at index \(index)",
            file: file,
            line: line
        )
    }
}

private extension FeedViewControllerTests {
    class LoaderSpy {
        private var _loadedImageURLs = [URL]()
        private var _feedRequests = [(FeedLoader.Result) -> Void]()
        
        func completeFeedLoading(
            with feed: [FeedImage] = [],
            at index: Int = 0
        ) {
            feedRequests[index](.success(feed))
        }
        
        func completeFeedLoadingWithError(at index: Int = 0) {
            feedRequests[index](.failure(anyNSError()))
        }
    }
}

extension FeedViewControllerTests.LoaderSpy: FeedLoader {
    var feedRequests: [(FeedLoader.Result) -> Void] {
        return _feedRequests
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        _feedRequests.append(completion)
    }
}

extension FeedViewControllerTests.LoaderSpy: FeedImageDataLoader {
    var loadedImageURLs: [URL] {
        return _loadedImageURLs
    }
    
    func loadImageData(from url: URL) {
        _loadedImageURLs.append(url)
    }
}

private extension UITableViewController {
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17Support()
        }
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    private func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        
        refreshControl?.allTargets.forEach { [weak self] target in
            self?.refreshControl?.actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?
                .forEach { action in
                    fake.addTarget(
                        target,
                        action: Selector(action),
                        for: .valueChanged
                    )
                }
        }
        
        refreshControl = fake
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { [weak self] target in
            self?.actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?
                .forEach { action in
                    (target as NSObject).perform(Selector(action))
                }
        }
    }
}

private extension FeedViewController {
    var isShowingReloadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    var numberOfRenderedFeedImageViews: Int {
        return tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    private var feedImagesSection: Int {
        return 0
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func simulateFeedImageViewVisible(at index: Int) {
        _ = feedImageView(at: index)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
    
    var locationText: String? {
        return locationLabel.text
    }
}
