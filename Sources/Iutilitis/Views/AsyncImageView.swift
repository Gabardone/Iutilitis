//
//  File.swift
//  
//
//  Created by Óscar Morales Vivó on 5/10/23.
//

#if canImport(UIKit)
import AutoLayoutHelpers
import UIKit

private let emptyPlaceholderSymbolName = "photo.artframe"

private let errorPlaceholderSymbolName = "xmark.diamond"

/**
 A simple wrapper for logic that asynchronously loads an image.

 The protocol requires a reference type as the `AsyncImageView` uses identity to ensure that the loaded results are
 still required by the calling instance.
 */
public protocol AsyncImageLoader: AnyObject {
    func loadImage() async throws -> UIImage?

    func cancel()
}

public extension AsyncImageLoader {
    func cancel() {
        // By default cancelation does nothing.
    }
}

/**
 A subclass of the framework's ImageView control that allows for async display of images.
 */
public class AsyncImageView: UIImageView {
    override init(frame: CGRect) {
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

    // MARK: - Stored Properties

    private var loadingTask: Task<UIImage, Error>?

    private let imageLoadingIndicator = UIActivityIndicatorView(style: .medium)

    private let placeholderImage = UIImageView(image: UIImage(systemName: emptyPlaceholderSymbolName))

    private var imageLoader: (any AsyncImageLoader)?

    // MARK: - Async Image

    public func load(imageLoader: AsyncImageLoader) {
        // Start image loading from cache.
        imageLoadingIndicator.startAnimating()
        placeholderImage.isHidden = true

        self.imageLoader = imageLoader
        Task { [imageLoader] in
            defer {
                // No matter how this ends the loading indicator goes away.
                imageLoadingIndicator.stopAnimating()
                self.imageLoader = nil
            }

            do {
                if let loadedImage = try await imageLoader.loadImage() {
                    // Set image if it's still loading the same one.
                    if self.imageLoader === imageLoader {
                        placeholderImage.isHidden = true
                        image = loadedImage
                    }
                } else {
                    // No image returned. Just clear out.
                    clearImage()
                }
            } catch {
                // Display an error placeholder.
                placeholderImage.isHidden = false
                placeholderImage.image = UIImage(systemName: errorPlaceholderSymbolName)
            }
        }
    }

    public func clearImage() {
        // Start by cleaning up the loading task info.
        imageLoader?.cancel()
        imageLoader = nil

        // Now clear the image and hide the progress indicator if needed.
        image = nil
        imageLoadingIndicator.stopAnimating()

        // Finally show the empty image view placeholder.
        placeholderImage.image = UIImage(systemName: emptyPlaceholderSymbolName)
        placeholderImage.isHidden = false
    }
}
#endif

