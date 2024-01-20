public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

public struct FeedViewModel {
    public let feed: [FeedImage]
}
