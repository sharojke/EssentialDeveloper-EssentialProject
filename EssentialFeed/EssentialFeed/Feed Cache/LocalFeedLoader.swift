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
    private enum ValidationError: Error {
        case invalidCache
    }
    
    func validateCache() throws {
        do {
            if let cache = try store.retrieve(),
               !FeedCachePrivacy.validate(cache.timestamp, against: currentDate()) {
                throw ValidationError.invalidCache
            }
        } catch {
            try store.deleteCachedFeed()
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
