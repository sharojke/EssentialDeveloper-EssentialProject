import Combine
import EssentialFeed

public extension Paginated {
    var loadMorePublisher: (() -> AnyPublisher<Self, Error>)? {
        guard let loadMore else { return nil }
        
        return {
            Deferred { Future(loadMore) }
                .eraseToAnyPublisher()
        }
    }
    
    init(
        items: [Item],
        loadMorePublisher: (() -> AnyPublisher<Self, Error>)?
    ) {
        let loadMore: ((@escaping LoadMoreCompletion) -> Void)? = loadMorePublisher
            .map { publisher in
                return { completion in
                    publisher()
                        .subscribe(
                            Subscribers.Sink(
                                receiveCompletion: { result in
                                    if case let .failure(error) = result {
                                        completion(.failure(error))
                                    }
                                },
                                receiveValue: { result in
                                    completion(.success(result))
                                }
                            )
                        )
                }
            }
        
        self.init(
            items: items,
            loadMore: loadMore
        )
    }
}

public extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>
    
    func getPublisher(url: URL) -> Publisher {
        var task: HTTPClientTask?
        
        return Deferred {
            Future { completion in
                task = get(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}

public extension LocalFeedLoader {
    typealias Publisher = AnyPublisher<[FeedImage], Error>
    
    func loadPublisher() -> Publisher {
        return Deferred { Future(self.load) }.eraseToAnyPublisher()
    }
}

public extension FeedImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>
    
    func loadImageDataPublisher(url: URL) -> Publisher {
        var task: FeedImageDataLoaderTask?
        
        return Deferred {
            Future { completion in
                task = loadImageData(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}

extension Publisher {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == [FeedImage] {
        return handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
    
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == Paginated<FeedImage> {
        return handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
}

extension Publisher where Output == Data {
    func caching(to cache: FeedImageDataCache, using url: URL) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveOutput: { data in
            cache.saveIgnoringResult(data, for: url)
        }).eraseToAnyPublisher()
    }
}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed) { _ in }
    }
    
    func saveIgnoringResult(_ page: Paginated<FeedImage>) {
        saveIgnoringResult(page.items)
    }
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ data: Data, for url: URL) {
        try? save(data, for: url)
    }
}

extension Publisher {
    func fallback(
        to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>
    ) -> AnyPublisher<Output, Failure> {
        return self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

extension Publisher {
    func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
        return receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler).eraseToAnyPublisher()
    }
}

extension DispatchQueue {
    struct ImmediateWhenOnMainQueueScheduler: Scheduler {
        // swiftlint:disable:next nesting
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        // swiftlint:disable:next nesting
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions
        
        static let shared = Self()
        private static let key = DispatchSpecificKey<UInt8>()
        private static let value = UInt8.max
        
        var now: SchedulerTimeType {
            return DispatchQueue.main.now
        }
        
        var minimumTolerance: SchedulerTimeType.Stride {
            return DispatchQueue.main.minimumTolerance
        }
        
        private init() {
            DispatchQueue.main.setSpecific(key: Self.key, value: Self.value)
        }
        
        func isMainQueue() -> Bool {
            return DispatchQueue.getSpecific(key: Self.key) == Self.value
        }
        
        func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            if isMainQueue() {
                action()
            } else {
                DispatchQueue.main.schedule(options: options, action)
            }
        }
        
        func schedule(
            after date: DispatchQueue.SchedulerTimeType,
            tolerance: DispatchQueue.SchedulerTimeType.Stride,
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            return DispatchQueue.main.schedule(
                after: date,
                tolerance: tolerance,
                options: options,
                action
            )
        }
        
        func schedule(
            after date: DispatchQueue.SchedulerTimeType,
            interval: DispatchQueue.SchedulerTimeType.Stride,
            tolerance: DispatchQueue.SchedulerTimeType.Stride,
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) -> Cancellable {
            return DispatchQueue.main.schedule(
                after: date,
                interval: interval,
                tolerance: tolerance,
                options: options,
                action
            )
        }
    }
    
    static var immediateWhenOnMainQueueScheduler: ImmediateWhenOnMainQueueScheduler {
        return ImmediateWhenOnMainQueueScheduler.shared
    }
}
