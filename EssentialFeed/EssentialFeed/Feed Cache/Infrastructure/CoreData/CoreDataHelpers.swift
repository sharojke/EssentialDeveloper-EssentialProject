import CoreData

extension NSPersistentContainer {
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
