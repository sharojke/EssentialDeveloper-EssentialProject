import Foundation

public enum FeedItemsMapper {
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(
        _ data: Data,
        from response: HTTPURLResponse
    ) throws -> [FeedImage] {
        guard response.isOK,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw Error.invalidData
        }
        
        return root.images
    }
}

private extension FeedItemsMapper {
    struct Root: Decodable {
        let items: [RemoteFeedItem]
        
        var images: [FeedImage] {
            return items.map { remoteFeedItem in
                FeedImage(
                    id: remoteFeedItem.id,
                    url: remoteFeedItem.image,
                    description: remoteFeedItem.description,
                    location: remoteFeedItem.location
                )
            }
        }
    }
}

private extension FeedItemsMapper.Root {
    struct RemoteFeedItem: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
    }
}
