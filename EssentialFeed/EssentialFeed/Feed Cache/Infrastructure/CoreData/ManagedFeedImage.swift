import CoreData

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
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
