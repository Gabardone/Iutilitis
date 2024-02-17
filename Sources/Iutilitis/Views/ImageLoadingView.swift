//
//  ImageLoadingView.swift
//
//
//  Created by Óscar Morales Vivó on 5/10/23.
//

import AutoLayoutHelpers
#if canImport(UIKit)
import UIKit

public typealias XXActivityIndicator = UIActivityIndicatorView
public typealias XXImage = UIImage
public typealias XXImageView = UIImageView
#elseif canImport(Cocoa)
import Cocoa

public typealias XXActivityIndicator = NSProgressIndicator
public typealias XXImage = NSImage
public typealias XXImageView = NSImageView

extension XXActivityIndicator {
    func startAnimating() {
        startAnimation(nil)
    }

    func stopAnimating() {
        stopAnimation(nil)
    }
}
#endif

/**
 A subclass of the framework's ImageView control that allows for async loading and of images.

 - Note: Because it's a generic class, it cannot be directly used in a .xib/.storyboard because Objective-C cannot
 deal with Swift generic classes. If you have the need to do so, create a subclass of `ImageLoadingView<ID>` with the ID
 type that you need and use that instead.
 */
@MainActor
open class ImageLoadingView<ImageID: Hashable>: XXImageView {
    deinit {
        // Just in case something is running and we can save some work.
        loadingTask?.cancel()
    }

    // MARK: - Types

    typealias Loader = (ImageID) async throws -> XXImage?

    // MARK: - Stored Properties

    public var imageID: ImageID? {
        get {
            currentImageID
        }

        set {
            guard imageID != newValue else {
                return
            }

            // Turn off ongoing task if any.
            loadingTask?.cancel()

            // Set the actual storage.
            currentImageID = newValue

            if let loader, let newValue {
                // Set up the loading.
                loadingTask = Task { [weak self, newValue] in
                    // Weak self deliberately left weak so if things go away during loader's execution everything else
                    // will not happen.
                    do {
                        if let image = try await loader(newValue) {
                            // Everything worked, display the image.
                            self?.display(image: image, imageID: newValue)
                        } else {
                            // No image found, display empty placeholder if set.
                            self?.display(placeholderImage: self?.emptyPlaceholderImage, imageID: newValue)
                        }
                    } catch is CancellationError {
                        // If things got canceled we just leave everything untouched, including loadingTask which is
                        // probably superseded by another one by now.
                        return
                    } catch {
                        // Set up the error placeholder if any.
                        self?.display(placeholderImage: self?.errorPlaceholderImage, imageID: newValue)
                    }
                }

                // Set up loading UI.
                ensureSpinner().startAnimating()
            } else {
                // Just leave it blank.
                imageLoadingIndicator?.stopAnimating()
                placeholderImageView?.isHidden = true
                super.image = nil
            }
        }
    }

    /**
     If set, it will be displayed when the image view is empty.

     This will display as a placeholder when `nil` is set for its loading ID, the loading operation is `nil` or the
     loading operation returns `nil` for a given ID.

     The image will be displayed at its original size.
     */
    public var emptyPlaceholderImage: XXImage?

    /**
     If set, it will be displayed when the image for a given ID fails to load.

     This will display as a placeholder when the load operation throws an exception.

     The image will be displayed at its original size.
     */
    public var errorPlaceholderImage: XXImage?

    /**
     The loading logic.

     The loader takes an imageID when set and attempts to load the image asynchronously. The loader will be wrapped in
     a `Task` so it should be able to use `Task` cancelation facilities to optimize work when a loading operation is no
     longer needed (the `Task` will be canceled when that happens).
     */
    var loader: Loader?

    private var currentImageID: ImageID?

    private var imageLoadingIndicator: XXActivityIndicator?

    private var placeholderImageView: XXImageView?

    private var loadingTask: Task<Void, Error>?

    // MARK: - XXImageView Overrides

    /**
     Setting the image directly will cancel any ongoing load operation and display the new value, even if `nil` or the
     same value that was being displayed.
     */
    override public var image: XXImage? {
        get {
            super.image
        }

        set {
            // We're setting it directly so make sure we also cancel any ongoing loading.
            imageID = nil
            loadingTask?.cancel()
            loadingTask = nil

            super.image = newValue
        }
    }
}

// MARK: - Setup Utilities

extension ImageLoadingView {
    func ensureSpinner() -> XXActivityIndicator {
        if let imageLoadingIndicator {
            return imageLoadingIndicator
        }

        // Gotta build it.
        let imageLoadingIndicator: XXActivityIndicator

        #if canImport(UIKit)
        // Configure UIKit
        imageLoadingIndicator = XXActivityIndicator(style: .medium)
        #elseif canImport(Cocoa)
        // Configure AppKit
        imageLoadingIndicator = XXActivityIndicator()
        imageLoadingIndicator.style = .spinning
        imageLoadingIndicator.isIndeterminate = true
        #endif

        // Store it for the next time.
        self.imageLoadingIndicator = imageLoadingIndicator

        // Add to view hierarchy and layout.
        add(subview: imageLoadingIndicator)
        NSLayoutConstraint.activate(imageLoadingIndicator.constraintsCenteringInSuperview())

        // We're good!
        return imageLoadingIndicator
    }

    func display(image: XXImage?, imageID: ImageID) {
        guard imageID == currentImageID else {
            // Stuff changed since we started loading the image. Let's walk back into the bushes.
            return
        }

        // Hide the rest of the stuff.
        placeholderImageView?.isHidden = true
        imageLoadingIndicator?.stopAnimating()

        // Actually display.
        super.image = image
    }

    func display(placeholderImage: XXImage?, imageID: ImageID) {
        guard imageID == currentImageID else {
            // Stuff changed since we started loading the image. Let's walk back into the bushes.
            return
        }

        // Make sure the rest of the stuff isn't showing.
        super.image = nil
        imageLoadingIndicator?.stopAnimating()

        guard let placeholderImage else {
            return
        }

        // Need to ensure the placeholder image view exists, then put the placeholder in.
        let placeholderImageView = placeholderImageView ?? {
            let placeholderImageView = XXImageView()

            // Store it for the next time.
            self.placeholderImageView = placeholderImageView

            // Add to view hierarchy and layout.
            add(subview: placeholderImageView)
            NSLayoutConstraint.activate(placeholderImageView.constraintsCenteringInSuperview())

            return placeholderImageView
        }()

        placeholderImageView.image = placeholderImage
        placeholderImageView.isHidden = false
    }
}
