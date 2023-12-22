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
    public typealias SaveResult = Error?
    
    public func save(
        _ feed: [FeedImage],
        completion: @escaping (SaveResult) -> Void
    ) {
        store.deleteCachedFeed { [weak self] error in
            guard let strongSelf = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                strongSelf.cache(feed) { [weak self] error in
                    guard self != nil else { return }
                    
                    completion(error)
                }
            }
        }
    }
    
    private func cache(
        _ items: [FeedImage],
        with completion: @escaping (SaveResult) -> Void
    ) {
        store.insert(
            feed: items.toLocal(),
            timestamp: currentDate(),
            completion: completion
        )
    }
}
    
extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .found(
                let feed,
                let timestamp
            ) where FeedCachePrivacy.validate(timestamp, against: strongSelf.currentDate()):
                completion(.success(feed.toModels()))
                
            case .empty, .found:
                completion(.success([]))
            }
        }
    }
}
    
public extension LocalFeedLoader {
    func validateCache() {
        store .retrieve { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .failure:
                self?.store.deleteCachedFeed { _ in }
                
            case .found(
                _,
                let timestamp
            ) where FeedCachePrivacy.validate(timestamp, against: strongSelf.currentDate()):
                break
                
            case .found:
                strongSelf.store.deleteCachedFeed { _ in }
                
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
