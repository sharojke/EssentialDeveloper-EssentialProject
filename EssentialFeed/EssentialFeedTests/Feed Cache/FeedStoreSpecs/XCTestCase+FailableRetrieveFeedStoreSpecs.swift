import EssentialFeed
import XCTest

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversFailureOnRetrievalError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(
            sut,
            toCompleteWithResult: .failure(anyNSError()),
            file: file,
            line: line
        )
    }
    
    func assertThatRetrieveHasNoSideEffectsOnFailure(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(
            sut,
            toRetrieveTwice: .failure(anyNSError()),
            file: file,
            line: line
        )
    }
}
