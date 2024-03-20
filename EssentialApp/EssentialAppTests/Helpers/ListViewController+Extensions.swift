import EssentialFeediOS
import UIKit

// swiftlint:disable force_unwrapping

extension ListViewController {
    var isShowingReloadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    var errorMessage: String? {
        return errorView.message
    }
    
    // swiftlint:disable:next override_in_extension
    override public func loadViewIfNeeded() {
        super.loadViewIfNeeded()
        
        tableView.frame = CGRect(x: .zero, y: .zero, width: 1, height: 1)
    }
    
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func simulateErrorViewTap() {
        errorView.simulateTap()
    }
    
    func numberOfRows(in section: Int) -> Int {
        tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
    }
    
    func cell(row: Int, section: Int) -> UITableViewCell? {
        guard numberOfRows(in: section) > row else { return nil }
        
        let dataSource = tableView.dataSource
        let index = IndexPath(row: row, section: section)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
}

extension ListViewController {
    var numberOfRenderedFeedImageViews: Int {
        return numberOfRows(in: feedImagesSection)
    }
    
    var isShowingLoadMoreIndicator: Bool {
        return loadMoreFeedCell()?.isLoading == true
    }
    
    private var feedImagesSection: Int {
        return 0
    }
    
    private var feedLoadMoreSection: Int {
        return 1
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewVisible(at: row)
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        
        delegate?.tableView?(
            tableView,
            didEndDisplaying: view!,
            forRowAt: index
        )
        return view
    }
    
    @discardableResult
    func simulateFeedImageBecomingVisibleAgain(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewNotVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, willDisplay: view!, forRowAt: index)
        
        return view
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
    
    func simulateTapOnFeedImage(at row: Int) {
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didSelectRowAt: index)
    }
    
    func simulateLoadMoreFeedAction() {
        guard let view = loadMoreFeedCell() else { return }
        
        let delegate = tableView.delegate
        let index = IndexPath(row: 0, section: feedLoadMoreSection)
        delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)
    }
    
    private func loadMoreFeedCell() -> LoadMoreCell? {
        return cell(row: 0, section: feedLoadMoreSection) as? LoadMoreCell
    }
    
    func renderedFeedImageData(at index: Int) -> Data? {
        return simulateFeedImageViewVisible(at: index)?.renderedImage
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        return cell(row: row, section: feedImagesSection)
    }
}

extension ListViewController {
    var numberOfRenderedComments: Int {
        return numberOfRows(in: commentsSection)
    }
    
    private var commentsSection: Int {
        return 0
    }
    
    func commentMessage(at row: Int) -> String? {
        commentView(at: row)?.messageLabel.text
    }
    
    func commentDate(at row: Int) -> String? {
        commentView(at: row)?.dateLabel.text
    }
    
    func commentUsername(at row: Int) -> String? {
        commentView(at: row)?.usernameLabel.text
    }
    
    private func commentView(at row: Int) -> ImageCommentCell? {
        return cell(row: row, section: commentsSection) as? ImageCommentCell
    }
}

// swiftlint:enable force_unwrapping
