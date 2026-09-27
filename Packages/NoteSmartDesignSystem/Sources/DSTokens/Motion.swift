import SwiftUI

/// Durations and springs. Motion is part of the system, not an ad-hoc value in a view.
public enum Motion {
    public enum Duration {
        public static let instant: Double = 0.1
        public static let fast: Double = 0.2
        public static let normal: Double = 0.3
        public static let slow: Double = 0.45
    }

    public enum Spring {
        /// Subtle state settles: selection, toggle, checkbox.
        public static let gentle = Animation.spring(response: 0.3, dampingFraction: 0.8)
        /// Entrances and dismissals with a little life.
        public static let snappy = Animation.spring(response: 0.38, dampingFraction: 0.68)
        /// Playful overshoot, reserved for the record pulse.
        public static let bouncy = Animation.spring(response: 0.45, dampingFraction: 0.6)
    }

    public static let pulse = Animation.easeInOut(duration: Duration.slow).repeatForever(autoreverses: true)

    /// Honours the system Reduce Motion setting by dropping the animation instead of
    /// merely shortening it.
    public static func resolve(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
