import Foundation

public class CoreDataFeedStore: FeedStore {
    public init() {}
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    }
    
    public func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}
