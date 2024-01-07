import EssentialFeed
import UIKit

final class FeedImageViewModel {
    typealias Observer<T> = (T) -> Void
    
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    
    var onImageLoad: Observer<UIImage>?
    var onImageLoadingStateChange: Observer<Bool>?
    var onShouldRetryImageLoadStateChange: Observer<Bool>?
    
    var description: String? {
        return model.description
    }
    
    var location: String? {
        return model.location
    }
    
    var hasLocation: Bool {
        return location != nil
    }
    
    init(
        model: FeedImage,
        imageLoader: FeedImageDataLoader
    ) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func loadImageData() {
        onImageLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            if let data = try? result.get(),
               let image = UIImage(data: data) {
                self?.onImageLoad?(image)
            } else {
                self?.onShouldRetryImageLoadStateChange?(true)
            }
            
            self?.onImageLoadingStateChange?(false)
        }
    }
    
    func preload() {
        task = imageLoader.loadImageData(from: model.url) { _ in }
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
        task = nil
    }
    
    private func handle(result: Result<Data, Error>) {
        if let data = try? result.get(),
           let image = UIImage(data: data) {
            onImageLoad?(image)
        } else {
            onShouldRetryImageLoadStateChange?(true)
        }
        onImageLoadingStateChange?(false)
    }
}
