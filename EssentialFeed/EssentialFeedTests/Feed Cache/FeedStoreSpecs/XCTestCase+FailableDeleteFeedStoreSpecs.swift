import EssentialFeed
import XCTest

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(
            deletionError,
            "Expected to delete with an error",
            file: file,
            line: line
        )
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        deleteCache(from: sut)
        
        expect(sut, toCompleteWithResult: .success(nil), file: file, line: line)
    }
}
