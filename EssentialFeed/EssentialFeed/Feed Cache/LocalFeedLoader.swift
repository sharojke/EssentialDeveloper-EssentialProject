import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}
    
extension LocalFeedLoader: FeedCache {
    public func save(_ feed: [FeedImage]) throws {
        try store.deleteCachedFeed()
        try store.insert(feed: feed.toLocal(), timestamp: currentDate())
    }
}
    
public extension LocalFeedLoader {
    func load() throws -> [FeedImage] {
        if let cache = try store.retrieve(),
           FeedCachePrivacy.validate(cache.timestamp, against: currentDate()) {
            return cache.feed.toModels()
        } else {
            return []
        }
    }
}
    
public extension LocalFeedLoader {
    typealias ValidationResult = Result<Void, Error>
    
    private enum ValidationError: Error {
        case invalidCache
    }
    
    func validateCache(completion: @escaping (ValidationResult) -> Void) {
        completion(
            ValidationResult {
                do {
                    if let cache = try store.retrieve(),
                       !FeedCachePrivacy.validate(cache.timestamp, against: currentDate()) {
                        throw ValidationError.invalidCache
                    }
                } catch {
                    try store.deleteCachedFeed()
                }
            }
        )
        
        store.retrieve { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .failure:
                strongSelf.store.deleteCachedFeed(completion: completion)
                
            case .success(let .some(cache)) where !FeedCachePrivacy.validate(
                cache.timestamp,
                against: strongSelf.currentDate()
            ):
                strongSelf.store.deleteCachedFeed(completion: completion)
                
            case .success:
                completion(.success(Void()))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { feedItem in
            LocalFeedImage(
                id: feedItem.id,
                url: feedItem.url,
                description: feedItem.description,
                location: feedItem.location
            )
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { feedItem in
            FeedImage(
                id: feedItem.id,
                url: feedItem.url,
                description: feedItem.description,
                location: feedItem.location
            )
        }
    }
}
