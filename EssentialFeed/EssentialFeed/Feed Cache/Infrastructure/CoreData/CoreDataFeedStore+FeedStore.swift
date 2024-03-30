extension CoreDataFeedStore: FeedStore {
    public func deleteCachedFeed() throws {
        try performSync { context in
            Result { try ManagedCache.deleteCache(in: context) }
        }
    }
    
    public func insert(feed: [LocalFeedImage], timestamp: Date) throws {
        try performSync { context in
            Result {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
                
                try context.save()
            }
        }
    }
    
    public func retrieve() throws -> CachedFeed? {
        try performSync { context in
            Result {
                try ManagedCache.find(in: context).map { cache in
                    CachedFeed(
                        feed: cache.localFeed,
                        timestamp: cache.timestamp
                    )
                }
            }
        }
    }
}
