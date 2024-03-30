import Combine
import EssentialFeed
import Foundation

typealias AnyDispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

struct AnyScheduler<SchedulerTimeType: Strideable, SchedulerOptions>: Scheduler 
where SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    private let _now: () -> SchedulerTimeType
    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _schedule: (SchedulerOptions?, @escaping () -> Void) -> Void
    
    private let _scheduleAfter: (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
    ) -> Void
    
    private let _scheduleAfterInterval: (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
    ) -> Cancellable

    var now: SchedulerTimeType { _now() }

    var minimumTolerance: SchedulerTimeType.Stride { _minimumTolerance() }
    
    init<S>(
        _ scheduler: S
    ) where SchedulerTimeType == S.SchedulerTimeType, SchedulerOptions == S.SchedulerOptions, S: Scheduler {
        _now = { scheduler.now }
        _minimumTolerance = { scheduler.minimumTolerance }
        _schedule = scheduler.schedule(options:_:)
        _scheduleAfter = scheduler.schedule(after:tolerance:options:_:)
        _scheduleAfterInterval = scheduler.schedule(after:interval:tolerance:options:_:)
    }

    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _schedule(options, action)
    }

    func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _scheduleAfter(date, tolerance, options, action)
    }

    func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        _scheduleAfterInterval(date, interval, tolerance, options, action)
    }
}

extension AnyDispatchQueueScheduler {
    static var immediateOnMainQueue: Self {
        DispatchQueue.immediateWhenOnMainQueueScheduler.eraseToAnyScheduler()
    }
}

extension Scheduler {
    func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
        AnyScheduler(self)
    }
}

// MARK: - CoreData

extension AnyDispatchQueueScheduler {
    private struct CoreDataFeedStoreScheduler: Scheduler {
        let store: CoreDataFeedStore
        var now: SchedulerTimeType { SchedulerTimeType(.now()) }
        var minimumTolerance: SchedulerTimeType.Stride { .zero }
        
        func schedule(
            after date: DispatchQueue.SchedulerTimeType,
            interval: DispatchQueue.SchedulerTimeType.Stride,
            tolerance: DispatchQueue.SchedulerTimeType.Stride,
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) -> any Cancellable {
            if store.contextQueue == .main, Thread.isMainThread {
                action()
            } else {
                store.perform(action)
            }
            return AnyCancellable {}
        }
        
        func schedule(
            after date: DispatchQueue.SchedulerTimeType,
            tolerance: DispatchQueue.SchedulerTimeType.Stride,
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            if store.contextQueue == .main, Thread.isMainThread {
                action()
            } else {
                store.perform(action)
            }
        }
        
        func schedule(
            options: DispatchQueue.SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            if store.contextQueue == .main, Thread.isMainThread {
                action()
            } else {
                store.perform(action)
            }
        }
    }
    
    static func scheduler(for store: CoreDataFeedStore) -> AnyDispatchQueueScheduler {
        CoreDataFeedStoreScheduler(store: store).eraseToAnyScheduler()
    }
}
