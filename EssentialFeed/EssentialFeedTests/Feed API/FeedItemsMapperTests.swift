import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class FeedItemsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let json = makeItemsJSON([])
        let samples = [199, 201, 300, 400, 500]
        
        try samples.forEach { code in
            XCTAssertThrowsError(try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: code)))
        }
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid.json".utf8)
        XCTAssertThrowsError(try FeedItemsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200)))
    }
    
    func test_map_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws {
        let emptyJSONList = makeItemsJSON([])
        
        let result = try FeedItemsMapper.map(emptyJSONList, from: HTTPURLResponse(statusCode: 200))
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func test_map_deliversItemsOn200HTTPResponseWithNotEmptyJSONList() throws {
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://url.com")!
        )
        
        let item2 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://url.com")!,
            description: "a description",
            location: "a location"
        )
        let json = makeItemsJSON([item1.json, item2.json])
        
        let result = try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: 200))
        
        XCTAssertEqual(result, [item1.model, item2.model])
    }
}

// MARK: - Helpers

extension FeedItemsMapperTests {
    private func makeItem(
        id: UUID,
        imageURL: URL,
        description: String? = nil,
        location: String? = nil
    ) -> (model: FeedImage, json: [String: Any]) {
        let model = FeedImage(
            id: id,
            url: imageURL,
            description: description,
            location: location
        )
        
        let json = [
            "id": model.id.uuidString,
            "description": model.description,
            "location": model.location,
            "image": model.url.absoluteString
        ].compactMapValues { $0 }
        
        return (model, json)
    }
}

// swiftlint:enable force_unwrapping
