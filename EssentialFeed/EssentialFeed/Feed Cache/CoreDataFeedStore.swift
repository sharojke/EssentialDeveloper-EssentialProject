import CoreData

// swiftlint:disable file_types_order
// swiftlint:disable force_unwrapping

public class CoreDataFeedStore: FeedStore {
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
        completion(nil)
    }
    
    public func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    ) {
        let context = context
        
        context.perform {
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
        let context = context
        
        context.perform {
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

private extension NSPersistentContainer {
    enum LoadingError: Error {
        case modelNotFound
        case failedToLoadPersistentStores(Error)
    }
    
    static func load(
        modelName name: String,
        url: URL,
        in bundle: Bundle
    ) throws -> Self {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw(LoadingError.modelNotFound)
        }
        
        let description = NSPersistentStoreDescription(url: url)
        let container = Self(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }
        
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> Self? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { Self(contentsOf: $0) }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
    var local: LocalFeedImage {
        return LocalFeedImage(
            id: id,
            url: url,
            description: imageDescription,
            location: location
        )
    }
    
    static func images(
        from localFeed: [LocalFeedImage],
        in context: NSManagedObjectContext
    ) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            
            return managed
        })
    }
}

// swiftlint:enable file_types_order
// swiftlint:enable force_unwrapping
