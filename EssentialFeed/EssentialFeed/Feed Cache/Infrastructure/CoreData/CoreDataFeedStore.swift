import CoreData

private enum CoreDataFeedStoreError: Error {
    case performSyncResultIsNotReached
}

public final class CoreDataFeedStore {
    enum StoreError: Error {
        case modelNotFound
        case failedToLoadPersistentContainer(Error)
    }
    
    private static let modelName = "FeedStore"
    
    public static let model = NSManagedObjectModel.with(
        name: modelName,
        in: Bundle(for: CoreDataFeedStore.self)
    )
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL) throws {
        guard let model = Self.model else {
            throw StoreError.modelNotFound
        }
        
        do {
            container = try NSPersistentContainer.load(
                name: Self.modelName,
                model: model,
                url: storeURL
            )
            context = container.newBackgroundContext()
        } catch {
            throw StoreError.failedToLoadPersistentContainer(error)
        }
    }
    
    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
    
    deinit {
        cleanUpReferencesToPersistentStores()
    }
}

// MARK: - Helpers

extension CoreDataFeedStore {
    func performAsync(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = context
        context.perform { action(context) }
    }
    
    func performSync<R>(_ action: (NSManagedObjectContext) -> Result<R, Error>) throws -> R {
        let context = context
        var result: Result<R, Error>?
        context.performAndWait { result = action(context) }
        
        guard let result else {
            throw CoreDataFeedStoreError.performSyncResultIsNotReached
        }
        
        return try result.get()
    }
}
