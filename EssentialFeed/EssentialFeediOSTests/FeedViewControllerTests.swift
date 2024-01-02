import EssentialFeed
import UIKit
import XCTest

final class FeedViewController: UITableViewController {
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(
            self,
            action: #selector(refresh),
            for: .valueChanged
        )
        
        onViewIsAppearing = { viewController in
            viewController.refresh()
            viewController.onViewIsAppearing = nil
        }
        
        load()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
    
    @objc 
    private func refresh() {
        refreshControl?.beginRefreshing()
        load()
    }
}

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
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.completions.isEmpty)
    }
    
    func test_viewDidLoad_loadFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.completions.count, 1)
    }
    
    func test_refreshControl_hasValidStatesOnVariousConditions() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
        
        sut.refreshControl?.endRefreshing()
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
        
        sut.refreshControl?.endRefreshing()
        sut.simulateAppearance()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    
    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.completions.count, 2)
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.completions.count, 3)
    }
    
    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        loader.completeFeedLoading()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    
    func test_pullToRefresh_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.refreshControl?.simulatePullToRefresh()
        loader.completeFeedLoading()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
}

// MARK: - Helpers

private extension FeedViewControllerTests {
    class LoaderSpy: FeedLoader {
        private (set) var completions = [(FeedLoader.Result) -> Void]()
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(at index: Int = 0) {
            completions[index](.success([]))
        }
    }
    
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: FeedViewController,
        loader: LoaderSpy
    ) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
}

private extension FeedViewController {
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17Support()
        }
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(
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
        allTargets.forEach { target in
            actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?
                .forEach { action in
                    (target as NSObject).perform(Selector(action))
                }
        }
    }
}
