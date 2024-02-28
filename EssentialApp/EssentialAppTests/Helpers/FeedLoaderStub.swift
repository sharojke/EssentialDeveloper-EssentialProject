import EssentialFeed

class FeedLoaderStub {
    private let result: Result<[FeedImage], Error>
    
    init(result: Result<[FeedImage], Error>) {
        self.result = result
    }
    
    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
        completion(result)
    }
}
