import CoreData

// swiftlint:disable force_unwrapping

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var data: Data?
    @NSManaged var cache: ManagedCache
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        managedObjectContext?.userInfo[url] = data
    }
}

// MARK: - Helpers

extension ManagedFeedImage {
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
        let images = NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            managed.data = context.userInfo[local.url] as? Data
            
            return managed
        })
        context.userInfo.removeAllObjects()
        return images
    }
    
    static func data(with url: URL, in context: NSManagedObjectContext) throws -> Data? {
        if let data = context.userInfo[url] as? Data {
            return data
        } else {
            return try first(with: url, in: context)?.data
        }
    }
    
    static func first(
        with url: URL,
        in context: NSManagedObjectContext
    ) throws -> ManagedFeedImage? {
        let request = NSFetchRequest<ManagedFeedImage>(entityName: entity().name!)
        request.predicate = NSPredicate(
            format: "%K = %@",
            argumentArray: [#keyPath(ManagedFeedImage.url), url]
        )
        request.returnsObjectsAsFaults = false
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

// swiftlint:enable force_unwrapping
