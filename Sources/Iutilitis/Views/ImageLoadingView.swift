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
@MainActor
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

    /**
     Loads an image using the provided block and sets it once it completes.

     Manages display of activity and both empty and error placeholder displays.

     The method checks at the end of the load operation to ensure that the image is not set if the view has been
     reconfigured since using either `load(loadOperation:cancelOperation)` or by directly setting a different image.
     - Parameter loadOperation: An asynchronous block that returns the image to display.
     - Parameter cancelOperation: Optionally, a block to run if the loading is canceled before completion by setting
     a different image directly.
     */
    public func load(loadOperation: @escaping LoadOperation, cancelOperation: CancelOperation? = nil) {
        // Start image loading from cache.
        imageLoadingIndicator.startAnimating()
        placeholderImage.isHidden = true

        let imageLoader = ImageLoader(loadOperation: loadOperation, cancelOperation: cancelOperation)
        self.imageLoader = imageLoader
        Task { [imageLoader] in
            do {
                // Set the image to whatever the image loader returns (could be nothing).
                // `finishLoadAndSet` will verify that the loader is the right one.
                try await finishLoadAndSet(imageLoader: imageLoader, image: imageLoader.loadOperation())
            } catch {
                // Display an error placeholder.
                finishLoadAndSet(imageLoader: imageLoader, image: nil, placeholder: Self.errorPlaceholderSymbolName)
            }
        }
    }

    /**
     If an ongoing image loading operation is ongoing, cancels it.

     Otherwise leaves things untouched, but will clear the error state if set.
     */
    public func cancelLoad() {
        imageLoader?.cancelOperation?()
        finishLoadAndSet(imageLoader: imageLoader, image: super.image)
    }

    private func finishLoadAndSet(
        imageLoader: ImageLoader?,
        image: UIImage?,
        placeholder: String = emptyPlaceholderSymbolName
    ) {
        guard imageLoader === self.imageLoader else {
            // The loader is no longer what we're waiting for, so let's just nop away.
            return
        }

        imageLoadingIndicator.stopAnimating()

        self.imageLoader = nil

        super.image = image // Skip the overridden property setter.

        // Show the empty placeholder if needed.
        placeholderImage.image = UIImage(systemName: placeholder)
        placeholderImage.isHidden = image != nil
    }

    // MARK: - UIImageView Overrides

    /**
     Setting the image directly will cancel any ongoing load operation and display the new value, even if `nil` or the
     same value that was being displayed.
     */
    override public var image: UIImage? {
        get {
            super.image
        }

        set {
            // We're setting it directly so make sure we also cancel any ongoing loading.
            imageLoader?.cancelOperation?()
            finishLoadAndSet(imageLoader: imageLoader, image: newValue)
        }
    }
}
#endif
