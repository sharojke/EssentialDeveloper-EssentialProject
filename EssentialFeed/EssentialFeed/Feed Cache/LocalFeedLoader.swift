import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Error?
    
    private let store: FeedStore
    let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
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
    
    private func cache(_ items: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(
            feed: items.toLocal(),
            timestamp: currentDate(),
            completion: completion
        )
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
