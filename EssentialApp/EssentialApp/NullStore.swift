import EssentialFeed

final class NullStore {}

extension NullStore: FeedStore {
    func deleteCachedFeed() throws {}
    func insert(feed: [LocalFeedImage], timestamp: Date) throws {}
    func retrieve() throws -> CachedFeed? {
        return nil
    }
}

extension NullStore: FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws {}
    
    func retrieve(dataForURL url: URL) throws -> Data? {
        return nil
    }
}
