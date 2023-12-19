import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(
        items: [LocalFeedItem],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    )
}
