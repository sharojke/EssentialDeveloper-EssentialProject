import CoreData

public final class CoreDataFeedStore {
    enum StoreError: Error {
        case modelNotFound
        case failedToLoadPersistentContainer(Error)
        case performSyncResultNotReached
    }
    
    public enum ContextQueue {
        case main
        case background
    }
    
    private static let modelName = "FeedStore"
    
    public static let model = NSManagedObjectModel.with(
        name: modelName,
        in: Bundle(for: CoreDataFeedStore.self)
    )
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public var contextQueue: ContextQueue {
        return context == container.viewContext ? .main : .background
    }
    
    public init(storeURL: URL, contextQueue: ContextQueue = .background) throws {
        guard let model = Self.model else {
            throw StoreError.modelNotFound
        }
        
        do {
            container = try NSPersistentContainer.load(
                name: Self.modelName,
                model: model,
                url: storeURL
            )
            context = contextQueue == .main ? container.viewContext : container.newBackgroundContext()
        } catch {
            throw StoreError.failedToLoadPersistentContainer(error)
        }
    }
    
    public func perform(_ action: @escaping () -> Void) {
        context.perform(action)
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
    func performSync<R>(_ action: (NSManagedObjectContext) -> Result<R, Error>) throws -> R {
        let context = context
        var result: Result<R, Error>?
        context.performAndWait { result = action(context) }
        
        guard let result else {
            throw StoreError.performSyncResultNotReached
        }
        
        return try result.get()
    }
}
