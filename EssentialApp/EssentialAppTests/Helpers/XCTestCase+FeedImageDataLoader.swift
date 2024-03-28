import EssentialFeed
import XCTest

protocol FeedImageDataLoaderTestCase: XCTestCase {
}

extension FeedImageDataLoaderTestCase {
    func expect(
        _ sut: FeedImageDataLoader,
        toCompleteWith expectedResult: Result<Data, Error>,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        action()
        let receivedResult = Result { try sut.loadImageData(from: anyURL()) }
        
        switch (receivedResult, expectedResult) {
        case let (.success(receivedData), .success(expectedData)):
            XCTAssertEqual(
                receivedData,
                expectedData,
                file: file,
                line: line
            )
            
        case (.failure, .failure):
            break
            
        default:
            XCTFail(
                "Expected \(expectedResult), got \(receivedResult) instead",
                file: file,
                line: line
            )
        }
    }
}
