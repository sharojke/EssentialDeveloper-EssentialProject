import EssentialFeed
import XCTest

final class FeedImageDataMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let samples = [199, 201, 300, 400, 500]
        
        try samples.forEach { code in
            XCTAssertThrowsError(
                try FeedImageDataMapper.map(
                    anyData(),
                    from: HTTPURLResponse(statusCode: code)
                )
            )
        }
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithEmptyData() {
        let emptyData = Data()
        XCTAssertThrowsError(try FeedImageDataMapper.map(emptyData, from: HTTPURLResponse(statusCode: 200)))
    }
    
    func test_map_deliversNonEmptyDataOn200HTTPResponse() throws {
        let nonEmptyData = anyData()
        let result = try FeedImageDataMapper.map(nonEmptyData, from: HTTPURLResponse(statusCode: 200))
        XCTAssertEqual(result, nonEmptyData)
    }
}
