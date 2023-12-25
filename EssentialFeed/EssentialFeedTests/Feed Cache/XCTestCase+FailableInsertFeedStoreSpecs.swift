import EssentialFeed
import XCTest

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let insertionError = insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        
        XCTAssertNotNil(
            insertionError,
            "Expected cache insertion to fail with an error",
            file: file,
            line: line
        )
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(
            (
                feed: uniqueImageFeed().local,
                timestamp: Date()
            ),
            into: sut
        )
        
        expect(sut, toCompleteWithResult: .empty)
    }
}
