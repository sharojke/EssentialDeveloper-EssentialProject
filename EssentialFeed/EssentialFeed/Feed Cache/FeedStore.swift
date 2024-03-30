import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias DeletionResult = Result<Void, Error>
    typealias DeletionCompletion = (DeletionResult) -> Void
    
    typealias InsertionResult = Result<Void, Error>
    typealias InsertionCompletion = (InsertionResult) -> Void
    
    typealias RetrievalResult = Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void
    
    /// The completion handler can be invoked in any thread
    /// Clients are responsible to dispatch to appropriate threads, if needed
    @available(*, deprecated)
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    
    /// The completion handler can be invoked in any thread
    /// Clients are responsible to dispatch to appropriate threads, if needed
    @available(*, deprecated)
    func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    )
    
    /// The completion handler can be invoked in any thread
    /// Clients are responsible to dispatch to appropriate threads, if needed
    @available(*, deprecated)
    func retrieve(completion: @escaping RetrievalCompletion)
    
    func deleteCachedFeed() throws
    func insert(feed: [LocalFeedImage], timestamp: Date) throws
    func retrieve() throws -> CachedFeed?
}

public extension FeedStore {
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {}
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {}
    func retrieve(completion: @escaping RetrievalCompletion) {}
    
    func deleteCachedFeed() throws {
        let dispatchGroup = DispatchGroup()
        
        // swiftlint:disable:next implicitly_unwrapped_optional
        var result: DeletionResult!
        dispatchGroup.enter()
        deleteCachedFeed { receivedResult in
            result = receivedResult
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return try result.get()
    }
    
    func insert(feed: [LocalFeedImage], timestamp: Date) throws {
        let dispatchGroup = DispatchGroup()
        
        // swiftlint:disable:next implicitly_unwrapped_optional
        var result: InsertionResult!
        dispatchGroup.enter()
        insert(feed: feed, timestamp: timestamp) { receivedResult in
            result = receivedResult
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return try result.get()
    }
    
    func retrieve() throws -> CachedFeed? {
        let dispatchGroup = DispatchGroup()
        
        // swiftlint:disable:next implicitly_unwrapped_optional
        var result: RetrievalResult!
        dispatchGroup.enter()
        retrieve() { receivedResult in
            result = receivedResult
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return try result.get()
    }
}
