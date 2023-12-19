import Foundation

public final class RemoteFeedLoader: FeedLoader {
    public typealias Result = LoadFeedResult
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> LoadFeedResult {
        do {
            let remote = try FeedItemsMapper.map(data, from: response)
            return .success(remote.toModels())
        } catch {
            return .failure(error)
        }
    }
    
    public func load(_ completion: @escaping (LoadFeedResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let data, let response):
                completion(Self.map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        return map { remoteFeedItem in
            FeedItem(
                id: remoteFeedItem.id,
                imageURL: remoteFeedItem.image,
                description: remoteFeedItem.description,
                location: remoteFeedItem.location
            )
        }
    }
}
