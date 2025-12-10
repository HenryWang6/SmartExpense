import SwiftUI
import UIKit

/// A transparent overlay that detects "hold to scrub" vs "swipe to scroll" gestures.
/// Uses UIKit gesture recognizers to properly coordinate with parent scroll views.
struct HoldToScrubOverlay: UIViewRepresentable {
    /// Called continuously while scrubbing with the x position (0...1 normalized)
    var onScrubbing: (CGFloat) -> Void
    /// Called when scrubbing ends
    var onScrubEnd: () -> Void
    /// Hold duration before scrubbing activates (seconds)
    var holdDuration: TimeInterval = 0.3
    /// Maximum movement allowed before hold is cancelled (points)
    var movementThreshold: CGFloat = 10
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let recognizer = HoldToScrubGestureRecognizer(
            holdDuration: holdDuration,
            movementThreshold: movementThreshold,
            target: context.coordinator,
            action: #selector(Coordinator.handleGesture(_:))
        )
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        view.addGestureRecognizer(recognizer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onScrubbing = onScrubbing
        context.coordinator.onScrubEnd = onScrubEnd
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScrubbing: onScrubbing, onScrubEnd: onScrubEnd)
    }
    
    class Coordinator: NSObject {
        var onScrubbing: (CGFloat) -> Void
        var onScrubEnd: () -> Void
        
        init(onScrubbing: @escaping (CGFloat) -> Void, onScrubEnd: @escaping () -> Void) {
            self.onScrubbing = onScrubbing
            self.onScrubEnd = onScrubEnd
        }
        
        @objc func handleGesture(_ recognizer: HoldToScrubGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let location = recognizer.location(in: view)
            let normalizedX = max(0, min(1, location.x / view.bounds.width))
            
            switch recognizer.state {
            case .began:
                // Haptic feedback when scrubbing starts
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onScrubbing(normalizedX)
            case .changed:
                onScrubbing(normalizedX)
            case .ended, .cancelled, .failed:
                onScrubEnd()
            default:
                break
            }
        }
    }
}

/// Custom gesture recognizer that waits for a hold before activating.
/// If the user moves too much before the hold duration, the gesture fails and
/// allows scroll views to handle the touch.
class HoldToScrubGestureRecognizer: UIGestureRecognizer {
    private let holdDuration: TimeInterval
    private let movementThreshold: CGFloat
    
    private var holdTimer: Timer?
    private var initialPoint: CGPoint = .zero
    private var hasActivated = false
    
    init(holdDuration: TimeInterval, movementThreshold: CGFloat, target: Any?, action: Selector?) {
        self.holdDuration = holdDuration
        self.movementThreshold = movementThreshold
        super.init(target: target, action: action)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        initialPoint = touch.location(in: view)
        hasActivated = false
        
        // Start hold timer
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: holdDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.state == .possible {
                self.hasActivated = true
                self.state = .began
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: view)
        
        if hasActivated {
            // Already scrubbing - update position
            state = .changed
        } else {
            // Check if movement exceeds threshold
            let dx = abs(currentPoint.x - initialPoint.x)
            let dy = abs(currentPoint.y - initialPoint.y)
            
            if dx > movementThreshold || dy > movementThreshold {
                // User is swiping - fail the gesture to let scroll view handle it
                holdTimer?.invalidate()
                holdTimer = nil
                state = .failed
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        holdTimer?.invalidate()
        holdTimer = nil
        
        if hasActivated {
            state = .ended
        } else {
            state = .failed
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        holdTimer?.invalidate()
        holdTimer = nil
        state = .cancelled
    }
    
    override func reset() {
        super.reset()
        holdTimer?.invalidate()
        holdTimer = nil
        hasActivated = false
        initialPoint = .zero
    }
}

