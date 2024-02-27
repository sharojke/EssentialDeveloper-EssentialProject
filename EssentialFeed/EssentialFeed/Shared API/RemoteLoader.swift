import Foundation

public final class RemoteLoader<Resource> {
    public typealias Result = Swift.Result<Resource, Swift.Error>
    public typealias Mapper = (Data, HTTPURLResponse) throws -> Resource
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private let url: URL
    private let client: HTTPClient
    private let mapper: Mapper
    
    public init(
        url: URL,
        client: HTTPClient,
        mapper: @escaping Mapper
    ) {
        self.url = url
        self.client = client
        self.mapper = mapper
    }
    
    private func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            return .success(try mapper(data, response))
        } catch {
            return .failure(Error.invalidData)
        }
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        _ = client.get(from: url) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success((let data, let response)):
                completion(map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
