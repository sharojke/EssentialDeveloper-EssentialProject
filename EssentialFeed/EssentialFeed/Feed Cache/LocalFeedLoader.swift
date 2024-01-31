import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}
    
extension LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>
    
    public func save(
        _ feed: [FeedImage],
        completion: @escaping (SaveResult) -> Void
    ) {
        store.deleteCachedFeed { [weak self] deletionResult in
            guard let strongSelf = self else { return }
            
            switch deletionResult {
            case .success:
                strongSelf.cache(feed, with: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func cache(
        _ items: [FeedImage],
        with completion: @escaping (SaveResult) -> Void
    ) {
        store.insert(
            feed: items.toLocal(),
            timestamp: currentDate()
        ) { [weak self] insertionResult in
            guard self != nil else { return }
            
            completion(insertionResult)
        }
    }
}
    
extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = FeedLoader.Result
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let .some(cache)) where FeedCachePrivacy.validate(
                cache.timestamp,
                against: strongSelf.currentDate()
            ):
                completion(.success(cache.feed.toModels()))
                
            case .success:
                completion(.success([]))
            }
        }
    }
}
    
public extension LocalFeedLoader {
    typealias ValidationResult = Result<Void, Error>
    
    func validateCache(completion: @escaping (ValidationResult) -> Void) {
        store .retrieve { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .failure:
                self?.store.deleteCachedFeed(completion: completion)
                
            case .success(let .some(cache)) where FeedCachePrivacy.validate(
                cache.timestamp,
                against: strongSelf.currentDate()
            ):
                completion(.success(Void()))
                
            case .success(.some):
                strongSelf.store.deleteCachedFeed { _ in completion(.success(Void())) }
                
            default:
                break
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
