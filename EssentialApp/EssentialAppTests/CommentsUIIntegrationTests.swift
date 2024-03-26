import Combine
import EssentialApp
import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

private class ThisLoaderSpy {
    private var requests = [PassthroughSubject<[ImageComment], Error>]()
    
    var loadCommentsCallCount: Int {
        return requests.count
    }
    
    func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
        let publisher = PassthroughSubject<[ImageComment], Error>()
        requests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeCommentsLoading(
        with comments: [ImageComment] = [],
        at index: Int = 0
    ) {
        requests[index].send(comments)
        requests[index].send(completion: .finished)
    }
    
    func completeCommentsLoadingWithError(at index: Int = 0) {
        requests[index].send(completion: .failure(anyNSError()))
        requests[index].send(completion: .finished)
    }
}

final class CommentsUIIntegrationTests: XCTestCase {
    func test_commentsView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    func test_loadCommentsActions_requestsCommentsFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertTrue(loader.loadCommentsCallCount == 0)
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            0,
            "Expected no loading requests before view is loaded"
        )
        
        sut.simulateAppearance()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            1,
            "Expected a loading requests once view is loaded"
        )
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            1,
            "Expected no requests until the prev completes"
        )
        
        loader.completeCommentsLoading(at: 0)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            2,
            "Expected another loading request once the the user initiates a load"
        )
        
        loader.completeCommentsLoading(at: 1)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            3,
            "Expected another loading request once the the user initiates another load"
        )
    }
    
    func test_loadCommentsActions_runsAutomaticallyOnlyOnFirstAppearance() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            0,
            "Expected no loading requests before view appears"
        )
        
        sut.simulateAppearance()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            1,
            "Expected a loading request once view appears"
        )
        
        sut.simulateAppearance()
        XCTAssertEqual(
            loader.loadCommentsCallCount,
            1,
            "Expected no loading request the second time view appears"
        )
    }
    
    func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(
            sut.isShowingReloadingIndicator,
            "Expected the loading indicator once the view is loaded"
        )
        
        loader.completeCommentsLoading(at: 0)
        XCTAssertFalse(
            sut.isShowingReloadingIndicator,
            "Expected no loading indicator once the the loading is completed successfully"
        )
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(
            sut.isShowingReloadingIndicator,
            "Expected the loading indicator once the user initiates a reload"
        )
        
        loader.completeCommentsLoadingWithError(at: 1)
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
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let (sut, loader) = makeSUT()
        let comment0 = makeComment(
            message: "a message",
            username: "a username"
        )
        let comment1 = makeComment(
            username: "another username"
        )
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [ImageComment]())
        
        loader.completeCommentsLoading(with: [comment0])
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() {
        let (sut, loader) = makeSUT()
        let comment0 = makeComment()
        
        sut.simulateAppearance()
        loader.completeCommentsLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoading(with: [], at: 1)
        assertThat(sut, isRendering: [ImageComment]())
    }
    
    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let (sut, loader) = makeSUT()
        let comment0 = makeComment(
            message: "a message",
            username: "a username"
        )
        
        sut.simulateAppearance()
        loader.completeCommentsLoading(with: [comment0])
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeCommentsLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment0])
    }
    
    func test_loadCommentsCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeCommentsLoading()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeCommentsLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeCommentsLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_deinit_cancelsRunningRequest() {
        var cancelCallCount = 0
        
        var sut: ListViewController?
        
        autoreleasepool {
            sut = CommentsUIComposer.commentsComposedWith {
                return PassthroughSubject<[ImageComment], Error>()
                    .handleEvents(receiveCancel: { cancelCallCount += 1 })
                    .eraseToAnyPublisher()
            }
            
            sut?.simulateAppearance()
        }
        
        XCTAssertEqual(cancelCallCount, 0)
        
        sut = nil
        
        XCTAssertEqual(cancelCallCount, 1)
    }
}

// MARK: - Helpers

private extension CommentsUIIntegrationTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: ListViewController,
        loader: ThisLoaderSpy
    ) {
        let loader = ThisLoaderSpy()
        let sut = CommentsUIComposer.commentsComposedWith(
            commentsLoader: loader.loadPublisher
        )
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    func makeComment(
        message: String = "any message",
        username: String = "any username"
    ) -> ImageComment {
        return ImageComment(
            id: UUID(),
            message: message,
            createdAt: Date(),
            username: username
        )
    }
    
    func assertThat(
        _ sut: ListViewController,
        isRendering comments: [ImageComment],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.view.enforceLayoutCycle()
        
        XCTAssertEqual(
            sut.numberOfRenderedComments,
            comments.count,
            "Comments count is wrong. Expected \(comments.count), got \(sut.numberOfRenderedComments) instead",
            file: file,
            line: line
        )
        
        // Used to get a model where `date` is a string and can be compared
        let viewModel = ImageCommentsPresenter.map(comments)
        
        viewModel.comments.enumerated().forEach { index, comment in
            XCTAssertEqual(
                sut.commentMessage(at: index),
                comment.message,
                "message at \(index)",
                file: file,
                line: line
            )
            
            XCTAssertEqual(
                sut.commentDate(at: index),
                comment.date,
                "date at \(index)",
                file: file,
                line: line
            )
            
            XCTAssertEqual(
                sut.commentUsername(at: index),
                comment.username,
                "username at \(index)",
                file: file,
                line: line
            )
        }
        
        executeRunLoopToCleanUpReferences()
    }
}
