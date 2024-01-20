public protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

public struct FeedLoadingViewModel {
    public let isLoading: Bool
}
