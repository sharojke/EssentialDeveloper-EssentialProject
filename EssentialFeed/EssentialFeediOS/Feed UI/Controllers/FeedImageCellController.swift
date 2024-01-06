import EssentialFeed
import UIKit

final class FeedImageCellController {
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    
    init(
        model: FeedImage,
        imageLoader: FeedImageDataLoader
    ) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = model.location == nil
        cell.descriptionLabel.text = model.description
        cell.locationLabel.text = model.location
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        
        let loadImage = { [weak self] in
            guard let self else { return }
            
            task = imageLoader.loadImageData(from: model.url) { [weak cell] result in
                let data = try? result.get()
                let image = data.flatMap(UIImage.init)
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = image != nil
                cell?.feedImageContainer.stopShimmering()
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        
        return cell
    }
    
    func preload() {
        task = imageLoader.loadImageData(from: model.url) { _ in }
    }
    
    func cancelLoad() {
        task?.cancel()
    }
}
