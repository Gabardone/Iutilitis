//
//  ImageLoadingView.swift
//
//
//  Created by Óscar Morales Vivó on 5/10/23.
//

#if canImport(UIKit)
import AutoLayoutHelpers
import UIKit

/**
 A subclass of the framework's ImageView control that allows for async display of images.
 */
public class ImageLoadingView: UIImageView {
    override public init(frame: CGRect = .zero) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    private func commonInit() {
        // Add the progress indicator, centered.
        add(subview: imageLoadingIndicator)
        add(subview: placeholderImage)
        (imageLoadingIndicator.constraintsCenteringInSuperview() + placeholderImage.constraintsCenteringInSuperview())
            .activate()
    }

    // MARK: - Types

    public typealias LoadOperation = () async throws -> UIImage?

    public typealias CancelOperation = () -> Void

    private class ImageLoader {
        init(loadOperation: @escaping LoadOperation, cancelOperation: CancelOperation? = nil) {
            self.loadOperation = loadOperation
            self.cancelOperation = cancelOperation
        }

        var loadOperation: LoadOperation

        var cancelOperation: CancelOperation?
    }

    // MARK: - Stored Properties

    private static let emptyPlaceholderSymbolName = "photo.artframe"

    private static let errorPlaceholderSymbolName = "xmark.diamond"

    private var loadingTask: Task<UIImage, Error>?

    private let imageLoadingIndicator = UIActivityIndicatorView(style: .medium)

    private let placeholderImage = UIImageView(image: UIImage(systemName: emptyPlaceholderSymbolName))

    private var imageLoader: ImageLoader?

    // MARK: - Async Image

    public func load(loadOperation: @escaping LoadOperation, cancelOperation: CancelOperation? = nil) {
        // Start image loading from cache.
        imageLoadingIndicator.startAnimating()
        placeholderImage.isHidden = true

        let imageLoader = ImageLoader(loadOperation: loadOperation, cancelOperation: cancelOperation)
        self.imageLoader = imageLoader
        Task { [imageLoader] in
            defer {
                // No matter how this ends the loading indicator goes away.
                imageLoadingIndicator.stopAnimating()
                self.imageLoader = nil
            }

            do {
                if let loadedImage = try await imageLoader.loadOperation() {
                    // Set image if it's still loading the same one.
                    if self.imageLoader === imageLoader {
                        image = loadedImage
                    }
                } else {
                    // No image returned. Just clear out.
                    image = nil
                }
            } catch {
                // Display an error placeholder.
                displayErrorState()
            }
        }
    }

    private func displayErrorState() {
        imageLoader?.cancelOperation?()
        imageLoader = nil

        super.image = nil // Skip `willSet` & `didSet`

        displayPlaceholder(name: Self.errorPlaceholderSymbolName)
    }

    private func displayPlaceholder(name: String) {
        // Clear the image and hide the progress indicator if needed.
        imageLoadingIndicator.stopAnimating()

        // Show the empty placeholder if needed.
        placeholderImage.image = UIImage(systemName: name)
        placeholderImage.isHidden = image != nil
    }

    // MARK: - UIImageView Overrides

    override public var image: UIImage? {
        willSet {
            guard let image, image != newValue else { return }

            // Clean up the loading task info.
            imageLoader?.cancelOperation?()
            imageLoader = nil
        }

        didSet {
            displayPlaceholder(name: Self.emptyPlaceholderSymbolName)
        }
    }
}
#endif
