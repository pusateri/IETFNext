//
//  ZoomableContainer.swift
//  IETFNext
//
//  Pinch-to-zoom, pan, and double-tap zoom for content such as a floor map.
//

import SwiftUI

/// Shows `content` so it can be zoomed and panned in place.
///
/// SwiftUI's `ScrollView` doesn't support zooming, so this hosts the content in the platform's
/// zooming scroll view: `UIScrollView` on iOS and `NSScrollView` magnification on macOS. That
/// gives native tracking (no gesture-recognition delay), zooming around the pinch point,
/// momentum, and edge bounce.
///
/// - Pinch (or trackpad pinch on the Mac) zooms between 1x and `maxScale`.
/// - Drag pans while zoomed.
/// - Double-tap (double-click on the Mac) toggles between fitting and `doubleTapScale`,
///   zooming toward the tapped point.
/// - VoiceOver users can zoom with the accessibility zoom action.
///
/// The content stays clipped to its own frame, so zooming never covers neighboring views.
struct ZoomableContainer<Content: View>: View {
    var maxScale: CGFloat = 5
    var doubleTapScale: CGFloat = 2.5
    @ViewBuilder var content: Content

    /// Lets the accessibility zoom action reach the platform scroll view.
    @State private var controller = ZoomController()

    var body: some View {
        ZoomingScrollRepresentable(controller: controller,
                                   maxScale: maxScale,
                                   doubleTapScale: doubleTapScale,
                                   content: content)
            .accessibilityZoomAction { action in
                switch action.direction {
                case .zoomIn:
                    controller.step(by: 0.5)
                case .zoomOut:
                    controller.step(by: -0.5)
                @unknown default:
                    break
                }
            }
            .accessibilityHint("Pinch or double-tap to zoom")
    }
}

#if os(macOS)
import AppKit

/// Holds a weak reference to the scroll view so SwiftUI actions can zoom it.
@MainActor
private final class ZoomController {
    weak var scrollView: NSScrollView?

    func step(by delta: CGFloat) {
        guard let scrollView else { return }
        let target = min(max(scrollView.magnification + delta, scrollView.minMagnification),
                         scrollView.maxMagnification)
        scrollView.animator().magnification = target
    }
}

/// An `NSScrollView` that keeps its document filling the visible area when not zoomed.
private final class ZoomingNSScrollView: NSScrollView {
    override func layout() {
        super.layout()
        if magnification == minMagnification, let documentView,
           documentView.frame.size != contentView.bounds.size {
            documentView.frame = CGRect(origin: .zero, size: contentView.bounds.size)
        }
    }
}

private struct ZoomingScrollRepresentable<Content: View>: NSViewRepresentable {
    let controller: ZoomController
    let maxScale: CGFloat
    let doubleTapScale: CGFloat
    let content: Content

    func makeCoordinator() -> Coordinator {
        Coordinator(hosting: NSHostingController(rootView: content), doubleTapScale: doubleTapScale)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ZoomingNSScrollView()
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = maxScale
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.documentView = context.coordinator.hosting.view

        let doubleClick = NSClickGestureRecognizer(target: context.coordinator,
                                                   action: #selector(Coordinator.doubleClicked(_:)))
        doubleClick.numberOfClicksRequired = 2
        scrollView.addGestureRecognizer(doubleClick)

        controller.scrollView = scrollView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hosting.rootView = content
        scrollView.maxMagnification = maxScale
    }

    /// Takes the content's fitted size (e.g. an aspect-fit map) for the proposed width.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        let height = proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        let fitted = context.coordinator.hosting.sizeThatFits(in: CGSize(width: width, height: height))
        return CGSize(width: width, height: fitted.height)
    }

    @MainActor
    final class Coordinator: NSObject {
        let hosting: NSHostingController<Content>
        let doubleTapScale: CGFloat

        init(hosting: NSHostingController<Content>, doubleTapScale: CGFloat) {
            self.hosting = hosting
            self.doubleTapScale = doubleTapScale
        }

        @objc func doubleClicked(_ recognizer: NSClickGestureRecognizer) {
            guard let scrollView = recognizer.view as? NSScrollView else { return }
            if scrollView.magnification > scrollView.minMagnification {
                scrollView.animator().magnification = scrollView.minMagnification
            } else if let documentView = scrollView.documentView {
                let point = recognizer.location(in: documentView)
                scrollView.animator().setMagnification(doubleTapScale, centeredAt: point)
            }
        }
    }
}

#else
import UIKit

/// Holds a weak reference to the scroll view so SwiftUI actions can zoom it.
@MainActor
private final class ZoomController {
    weak var scrollView: UIScrollView?

    func step(by delta: CGFloat) {
        guard let scrollView else { return }
        let target = min(max(scrollView.zoomScale + delta, scrollView.minimumZoomScale),
                         scrollView.maximumZoomScale)
        scrollView.setZoomScale(target, animated: true)
    }
}

/// A `UIScrollView` that keeps its zoomed view filling its bounds when not zoomed,
/// for example after rotation or a column resize.
private final class ZoomingUIScrollView: UIScrollView {
    weak var zoomedView: UIView?

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale == minimumZoomScale, let zoomedView, zoomedView.frame.size != bounds.size {
            zoomedView.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size
        }
    }
}

private struct ZoomingScrollRepresentable<Content: View>: UIViewRepresentable {
    let controller: ZoomController
    let maxScale: CGFloat
    let doubleTapScale: CGFloat
    let content: Content

    func makeCoordinator() -> Coordinator {
        let hosting = UIHostingController(rootView: content)
        // The scroll view supplies the frame; the hosted content shouldn't add safe-area insets.
        hosting.safeAreaRegions = []
        hosting.view.backgroundColor = .clear
        return Coordinator(hosting: hosting, doubleTapScale: doubleTapScale)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = ZoomingUIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = maxScale
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .clear

        let hostedView = context.coordinator.hosting.view!
        scrollView.addSubview(hostedView)
        scrollView.zoomedView = hostedView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        controller.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hosting.rootView = content
        scrollView.maximumZoomScale = maxScale
    }

    /// Takes the content's fitted size (e.g. an aspect-fit map) for the proposed width.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIScrollView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        let height = proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        let fitted = context.coordinator.hosting.sizeThatFits(in: CGSize(width: width, height: height))
        return CGSize(width: width, height: fitted.height)
    }

    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hosting: UIHostingController<Content>
        let doubleTapScale: CGFloat

        init(hosting: UIHostingController<Content>, doubleTapScale: CGFloat) {
            self.hosting = hosting
            self.doubleTapScale = doubleTapScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hosting.view
        }

        @objc func doubleTapped(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView = recognizer.view as? UIScrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                // Zoom toward the tapped point.
                let point = recognizer.location(in: hosting.view)
                let size = CGSize(width: scrollView.bounds.width / doubleTapScale,
                                  height: scrollView.bounds.height / doubleTapScale)
                let rect = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                                  width: size.width, height: size.height)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}
#endif
