import CoreData

extension NSPersistentContainer {
    static func load(
        name: String,
        model: NSManagedObjectModel,
        url: URL
    ) throws -> Self {
        let description = NSPersistentStoreDescription(url: url)
        let container = Self(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }
        
        return container
    }
}

extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> Self? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { Self(contentsOf: $0) }
    }
}

extension NSManagedObjectModel {
    convenience init?(name: String, in bundle: Bundle) {
        guard let momd = bundle.url(
            forResource: name,
            withExtension: "momd"
        ) else {
            return nil
        }
        
        self.init(contentsOf: momd)
    }
}
