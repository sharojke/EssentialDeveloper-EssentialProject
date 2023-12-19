import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

internal enum FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static let OK_200 = 200
    
    internal static func map(
        _ data: Data,
        from response: HTTPURLResponse
    ) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
