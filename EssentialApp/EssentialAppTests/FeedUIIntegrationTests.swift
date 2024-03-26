import EssentialApp
import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable force_unwrapping
// swiftlint:disable file_length

class FeedUIIntegrationTests: XCTestCase {
    func test_feedView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.title, feedTitle)
    }
    
    func test_imageSelection_notifiesHandler() {
        let image0 = makeImage()
        let image1 = makeImage()
        var selectedImages = [FeedImage]()
        let (sut, loader) = makeSUT { selectedImages.append($0) }
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1], at: 0)
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateTapOnFeedImage(at: 0)
        XCTAssertEqual(selectedImages, [image0])
        
        sut.simulateTapOnFeedImage(at: 1)
        XCTAssertEqual(selectedImages, [image0, image1])
    }
    
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
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(
            loader.feedRequests.count,
            1,
            "Expected no request until the prev completes"
        )
        
        loader.completeFeedLoading(at: 0)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(
            loader.feedRequests.count,
            2,
            "Expected another loading request once the the user initiates a load"
        )
        
        loader.completeFeedLoading(at: 1)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(
            loader.feedRequests.count,
            3,
            "Expected another loading request once the the user initiates another load"
        )
    }
    
    func test_loadFeedActions_runsAutomaticallyOnlyOnFirstAppearance() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(
            loader.feedRequests.count,
            0,
            "Expected no loading requests before view appears"
        )
        
        sut.simulateAppearance()
        XCTAssertEqual(
            loader.feedRequests.count,
            1,
            "Expected a loading request once view appears"
        )
        
        sut.simulateAppearance()
        XCTAssertEqual(
            loader.feedRequests.count,
            1,
            "Expected no loading request the second time view appears"
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
        
        sut.simulateUserInitiatedReload()
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
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMore(with: [image0, image1, image2, image3], at: 0)
        assertThat(sut, isRendering: [image0, image1, image2, image3])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(with: [image0, image1], at: 1)
        assertThat(sut, isRendering: [image0, image1])
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage()
        let image1 = makeImage()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMore(with: [image0, image1], at: 0)
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
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
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMoreWithError(at: 0)
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
    
    func test_feedImageView_cancelsImageLoadingWhenNotVisibleAnymore() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage()
        let image1 = makeImage()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [],
            "Expected no cancelled image URLs until image gets invisible"
        )
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url],
            "Expected one cancelled image URL request once the first image isn't visible"
        )
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url, image1.url],
            "Expected two cancelled image URL requests once the second image is also not visible"
        )
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the first view while loading the the first image"
        )
        XCTAssertEqual(
            view1?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the second view while loading the the second image"
        )
        
        loader.completeImageLoading(at: 0)
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the first view while it's loaded successfully"
        )
        XCTAssertEqual(
            view1?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the second view since the loading isn't finished yet"
        )
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator state change for the first view once the second image loading completes with error"
        )
        XCTAssertEqual(
            view1?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the second view once the second image loading completes with  error"
        )
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            view0?.renderedImage,
            nil,
            "Expected no image for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1?.renderedImage,
            nil,
            "Expected no image for the second view while loading the second image"
        )
        
        let imageData0 = anyImageData()
        loader.completeImageLoading(with: imageData0, at: 0)
        XCTAssertEqual(
            view0?.renderedImage,
            imageData0,
            "Expected an image for the first view while the first image loading is completed successfully"
        )
        XCTAssertEqual(
            view1?.renderedImage,
            nil,
            "Expected no image for the second view on the first image loading is completed successfully"
        )
        
        let imageData1 = anyImageData()
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(
            view0?.renderedImage,
            imageData0,
            "Expected no image state change for the first view on the second image loading is completed successfully"
        )
        XCTAssertEqual(
            view1?.renderedImage,
            imageData1,
            "Expected an image for the second view while the second image loading is completed successfully"
        )
    }
    
    func test_feedImageView_reloadsImageURLWhenBecomingVisibleAgain() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        sut.simulateFeedImageBecomingVisibleAgain(at: 0)
        
        XCTAssertEqual(
            loader.loadedImageURLs,
            [
                image0.url,
                image0.url
            ],
            "Expected two image URL request after first view becomes visible again"
        )
        
        sut.simulateFeedImageBecomingVisibleAgain(at: 1)
        
        XCTAssertEqual(
            loader.loadedImageURLs,
            [
                image0.url,
                image0.url,
                image1.url,
                image1.url
            ],
            "Expected two new image URL request after second view becomes visible again"
        )
    }
    
    func test_feedImageView_configuresViewCorrectlyWhenCellBecomingVisibleAgain() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view0 = sut.simulateFeedImageBecomingVisibleAgain(at: 0)
        
        XCTAssertEqual(
            view0?.renderedImage,
            nil,
            "Expected no rendered image when view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry action when view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator when view becomes visible again"
        )
        
        let imageData = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData, at: 1)
        
        XCTAssertEqual(
            view0?.renderedImage,
            imageData,
            "Expected rendered image when image loads successfully after view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry when image loads successfully after view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator when image loads successfully after view becomes visible again"
        )
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(
            view?.isShowingRetryAction,
            false,
            "Expected no retry action while loading the image"
        )
        
        let imageData = Data("invalid image data".utf8)
        loader.completeImageLoading(with: imageData)
        XCTAssertEqual(
            view?.isShowingRetryAction,
            true,
            "Expected the retry action to be visible since the image image loading completes with a invalid image data"
        )
    }
    
    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry action for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1?.isShowingRetryAction,
            false,
            "Expected no retry action for the second view while loading the second image"
        )
        
        let imageData0 = anyImageData()
        loader.completeImageLoading(with: imageData0, at: 0)
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry action for the first view on the first image loading is completed successfully"
        )
        XCTAssertEqual(
            view1?.isShowingRetryAction,
            false,
            "Expected no retry action for the second view on the first image loading is completed successfully"
        )
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry action state change for the first view on the second image loading is completed with an error"
        )
        XCTAssertEqual(
            view1?.isShowingRetryAction,
            true,
            "Expected a retry action for the second view while the second image loading is completed with an error"
        )
    }
    
    func test_feedImageViewRetryAction_retriesImageLoad() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage()
        let image1 = makeImage()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected two image URL request for the two visible views"
        )
        
        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected only two image URL requests before retry action"
        )
        
        view0?.simulateRetryAction()
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url, image0.url],
            "Expected third imageURL request after first view retry action"
        )
        
        view1?.simulateRetryAction()
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url, image0.url, image1.url],
            "Expected fourth imageURL request after second view retry action"
        )
    }
    
    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage()
        let image1 = makeImage()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(
            loader.loadedImageURLs,
            [],
            "Expected no image URL requests until image is near visible"
        )
        
        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url],
            "Expected the first url request once the first image view is near visible"
        )
        
        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected the second url request once the second image view is near visible"
        )
    }
    
    func test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let (sut, loader) = makeSUT()
        let image0 = makeImage()
        let image1 = makeImage()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [],
            "Expected no cancelled image URL requests until image is not near visible"
        )
        
        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url],
            "Expected the first url request is cancelled once the first image view is not near visible"
        )

        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url, image1.url],
            "Expected the second url request is cancelled once the second image view is not near visible"
        )
    }
    
    func test_feedImageView_doesNotLoadImageAgainUntilPreviousRequestCompletes() {
        let (sut, loader) = makeSUT()
        let image = makeImage()
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image])
        
        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image.url],
            "Expected first request when near visible"
        )
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image.url],
            "Expected no request until the prev completes"
        )
        
        loader.completeImageLoading(at: 0)
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image.url, image.url],
            "Expected the second request when visible after the previous completes"
        )
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image.url, image.url, image.url],
            "Expected the third url request is cancelled once the second image view is not near visible"
        )
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMore(with: [image, makeImage()])
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image.url, image.url, image.url],
            "Expected no requests until the prev completes"
        )
    }
    
    func test_feedImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewNotVisible(at: 0)
        loader.completeImageLoading(with: anyImageData())
        
        XCTAssertNil(
            view?.renderedImage,
            "Expected not rendered message when an image load finished after the view is not visible anymore"
        )
    }
    
    func test_feedImageView_doesNotShowDataFromPreviousRequestWhenCellIsReused() throws {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        view0.prepareForReuse()
        
        let imageData0 = anyImageData()
        loader.completeImageLoading(with: imageData0, at: 0)
        
        XCTAssertNil(
            view0.renderedImage,
            "Expected no image state change for reused view once image loading completes successfully"
        )
    }
    
    func test_feedImageView_showsDataForNewViewRequestAfterPreviousViewIsReused() throws {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let previousView = try XCTUnwrap(sut.simulateFeedImageViewNotVisible(at: 0))
        
        let newView = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        previousView.prepareForReuse()
        
        let imageData = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData, at: 1)
        
        XCTAssertEqual(newView.renderedImage, imageData)
    }
    
    func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeFeedLoading()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadImageDataCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        sut.simulateFeedImageViewVisible(at: 0)
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeImageLoading()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    // MARK: - Load More Tests
    
    func test_loadMoreActions_requestsMoreFromLoader() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        XCTAssertEqual(
            loader.loadMoreRequests.count,
            0,
            "Expected no requests until load more action"
        )
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(
            loader.loadMoreRequests.count,
            1,
            "Expected a load more requests"
        )
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(
            loader.loadMoreRequests.count,
            1,
            "Expected no additional requests while loading more"
        )
        
        loader.completeLoadMore(with: [], lastPage: false, at: 0)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(
            loader.loadMoreRequests.count,
            2,
            "Expected request after load more completed with more pages"
        )

        loader.completeLoadMoreWithError(at: 1)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(
            loader.loadMoreRequests.count,
            3,
            "Expected request after load more failure"
        )

        loader.completeLoadMore(with: [], lastPage: true, at: 2)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(
            loader.loadMoreRequests.count,
            3,
            "Expected no request after loading all pages"
        )
    }
    
    func test_loadingMoreIndicator_isVisibleWhileLoadingMore() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertFalse(
            sut.isShowingLoadMoreIndicator,
            "Expected no loading indicator once view is loaded"
        )
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(
            sut.isShowingLoadMoreIndicator,
            "Expected no loading indicator once loading completes successfully"
        )
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertTrue(
            sut.isShowingLoadMoreIndicator,
            "Expected loading indicator on load more action"
        )
        
        loader.completeLoadMore(with: [], at: 0)
        XCTAssertFalse(
            sut.isShowingLoadMoreIndicator,
            "Expected no loading indicator once user initiated loading completes successfully"
        )
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertTrue(
            sut.isShowingLoadMoreIndicator,
            "Expected loading indicator on second load more action"
        )
        
        loader.completeLoadMoreWithError(at: 1)
        XCTAssertFalse(
            sut.isShowingLoadMoreIndicator,
            "Expected no loading indicator once user initiated loading completes with error"
        )
    }
    
    func test_loadMoreCompletion_rendersErrorMessageOnError() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, nil)
        
        loader.completeLoadMoreWithError(at: 0)
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, loadError)
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, nil)
    }
    
    func test_tapOnLoadMoreErrorView_loadsMore() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreRequests.count, 1)
        
        sut.simulateTapOnLoadMoreFeedError()
        XCTAssertEqual(loader.loadMoreRequests.count, 1)
        
        loader.completeLoadMoreWithError(at: 0)
        sut.simulateTapOnLoadMoreFeedError()
        XCTAssertEqual(loader.loadMoreRequests.count, 2)
    }
    
    func test_loadMoreCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        sut.simulateLoadMoreFeedAction()
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeLoadMore(with: [])
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

// MARK: - Helpers

private extension FeedUIIntegrationTests {
    func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line,
        selection: @escaping (FeedImage) -> Void = { _ in }
    ) -> (
        sut: ListViewController,
        loader: LoaderSpy
    ) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(
            feedLoader: loader.loadPublisher,
            imageLoader: loader.loadImageDataPublisher,
            selection: selection
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
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable force_unwrapping
// swiftlint:enable file_length
