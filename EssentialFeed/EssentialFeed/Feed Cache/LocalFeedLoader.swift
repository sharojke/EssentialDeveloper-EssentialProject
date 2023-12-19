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
        _ items: [FeedItem],
        completion: @escaping (SaveResult) -> Void
    ) {
        store.deleteCachedFeed { [weak self] error in
            guard let strongSelf = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                strongSelf.cache(items) { [weak self] error in
                    guard self != nil else { return }
                    
                    completion(error)
                }
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(
            items: items,
            timestamp: currentDate(),
            completion: completion
        )
    }
}
