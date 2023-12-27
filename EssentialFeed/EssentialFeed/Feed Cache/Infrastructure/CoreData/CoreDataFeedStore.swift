import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(
        storeURL: URL,
        bundle: Bundle = .main
    ) throws {
        container = try NSPersistentContainer.load(
            modelName: "FeedStore",
            url: storeURL,
            in: bundle
        )
        context = container.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            do {
                try ManagedCache.find(in: context)
                    .map(context.delete)
                    .map(context.save)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    ) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
                
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(
                        .success(
                            CacheFeed(
                                feed: cache.localFeed,
                                timestamp: cache.timestamp
                            )
                        )
                    )
                } else {
                    completion(.success(nil))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Helpers

private extension CoreDataFeedStore {
    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = context
        context.perform { action(context) }
    }
}
