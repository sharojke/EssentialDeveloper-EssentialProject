import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    )
    func retrieve(completion: @escaping RetrievalCompletion)
}
