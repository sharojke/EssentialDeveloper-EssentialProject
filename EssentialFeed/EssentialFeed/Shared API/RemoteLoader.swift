import Foundation

public final class RemoteLoader: FeedLoader {
    public typealias Result = FeedLoader.Result
    
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
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let images = try FeedItemsMapper.map(data, from: response)
            return .success(images)
        } catch {
            return .failure(Error.invalidData)
        }
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        _ = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success((let data, let response)):
                completion(Self.map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
