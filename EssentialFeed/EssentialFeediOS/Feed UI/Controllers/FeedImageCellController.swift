import EssentialFeed
import UIKit

// swiftlint:disable weak_delegate
// swiftlint:disable force_unwrapping

public protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}

public final class FeedImageCellController {
    private let viewModel: FeedImageViewModel
    private let delegate: FeedImageCellControllerDelegate
    private var cell: FeedImageCell?
    
    public init(
        viewModel: FeedImageViewModel,
        delegate: FeedImageCellControllerDelegate
    ) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()
        cell?.locationContainer.isHidden = !viewModel.hasLocation
        cell?.locationLabel.text = viewModel.location
        cell?.descriptionLabel.text = viewModel.description
        cell?.onRetry = delegate.didRequestImage
        cell?.onReuse = { [weak self] in
            self?.releaseCellForReuse()
        }
        delegate.didRequestImage()
        return cell!
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelImageRequest()
    }
        
    func releaseCellForReuse() {
        cell?.onReuse = nil
        cell = nil
    }
}

extension FeedImageCellController: ResourceView {
    public typealias ResourceViewModel = UIImage
    
    public func display(_ viewModel: UIImage) {
        cell?.feedImageView.setImageAnimated(viewModel)
        cell?.onReuse = { [weak self] in
            self?.releaseCellForReuse()
        }
    }
}

extension FeedImageCellController: ResourceLoadingView {
    public func display(_ viewModel: EssentialFeed.ResourceLoadingViewModel) {
        cell?.feedImageContainer.isShimmering = viewModel.isLoading
    }
}

extension FeedImageCellController: ResourceErrorView {
    public func display(_ viewModel: EssentialFeed.ResourceErrorViewModel) {
        cell?.feedImageRetryButton.isHidden = viewModel.message == nil
    }
}

// swiftlint:enable weak_delegate
// swiftlint:enable force_unwrapping
