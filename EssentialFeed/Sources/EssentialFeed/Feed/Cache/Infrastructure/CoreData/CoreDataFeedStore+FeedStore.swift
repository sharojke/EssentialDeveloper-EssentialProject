import Foundation

extension CoreDataFeedStore: FeedStore {
    public func deleteCachedFeed() throws {
        try ManagedCache.deleteCache(in: context)
    }
    
    public func insert(feed: [LocalFeedImage], timestamp: Date) throws {
        let managedCache = try ManagedCache.newUniqueInstance(in: context)
        
        managedCache.timestamp = timestamp
        managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
        
        try context.save()
    }
    
    public func retrieve() throws -> CachedFeed? {
        try ManagedCache.find(in: context).map { cache in
            CachedFeed(
                feed: cache.localFeed,
                timestamp: cache.timestamp
            )
        }
    }
}
