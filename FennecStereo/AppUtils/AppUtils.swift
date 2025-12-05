//
//  AppUtils.swift

import Foundation
import SwiftUI
import Combine

final class AppUtils {
    // Singleton instance
    static let shared = AppUtils()
    private init() {}
    
    func hapticEffect(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Device & Screen Utilities
    
    /// Check if device is iPhone
    static var isiPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Check if device is iPad
    static var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns screen width
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    /// Returns screen height
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    /// Returns safe area insets
    static var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
    }
    
    /// Generates a random string of given length
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    // MARK: - UI Utilities
    
    /// Hides the keyboard
    static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Opens URL with safety check
    static func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    /// Returns a color from hex string
    static func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
    
    
    // MARK: - Animation Utilities
    
    /// Standard animation for UI interactions
    static var standardEaseInOut: Animation {
        .easeInOut(duration: 0.3)
    }
    
    /// Spring animation for more prominent effects
    static var springyBounce: Animation {
        .interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)
    }
    
    // MARK: - Debug Utilities
    
    /// Prints all available fonts
    static func printAllFonts() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }
    
    /// Conditional debug print
    static func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        print(items, separator: separator, terminator: terminator)
        #endif
    }
    
    
    // Image convert into base 64
    static func imageToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return ""
        }
        return imageData.base64EncodedString()
    }
    
    static  func convertImagesToBase64(_ images: [UIImage]) -> [String] {
        images.compactMap { image in
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                return imageData.base64EncodedString()
            } else {
                return nil
            }
        }
    }

    static var timestamp: String {
        return "\(Int(Date().timeIntervalSince1970 * 1000))"
    }
   
    static  func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
        
    }
    
    // Helper to convert date string to relative time
    func relativeTimeString(from dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let dateValue = date else { return "" }
        let now = Date()
        let seconds = Int(now.timeIntervalSince(dateValue))
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let min = seconds / 60
            return "\(min) min ago"
        } else if seconds < 86400 {
            let hr = seconds / 3600
            return "\(hr) hour\(hr > 1 ? "s" : "") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days > 1 ? "s" : "") ago"
        }
    }
    
    // MARK: - Alert Utilities
    /// Presents a custom delete confirmation alert with blur and color
    static func presentDeleteConfirmationAlert(on viewController: UIViewController, title: String = "Delete this look ?", cancelTitle: String = "Cancel", confirmTitle: String = "Confirm", confirmHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: title, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.systemBlue, forKey: "titleTextColor")
        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            confirmHandler()
        }
        confirmAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        viewController.present(alert, animated: true) {
            // Customization for background color and blur
            if let bgView = alert.view.subviews.first?.subviews.first?.subviews.first {
                bgView.backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.75) // #1E1E1EBF
                bgView.layer.cornerRadius = 16
                // Add extra blur
                let blurEffect = UIBlurEffect(style: .systemMaterialDark)
                let blurView = UIVisualEffectView(effect: blurEffect)
                blurView.frame = bgView.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                bgView.insertSubview(blurView, at: 0)
            }
        }
    }
    
    func getAppName() -> String {
        return "Fennec Stereo"
    }

    static func hasTopSafeArea(_ geometry: GeometryProxy) -> Bool {
        return geometry.safeAreaInsets.top > 0
    }

    static func containsMarkdown(_ text: String) -> Bool {
        let markdownPatterns: [String] = [
            #"(?m)^#{1,6}\s"#,                      // Headings #, ##, ### etc.
            #"\*\*.*?\*\*"#,                       // Bold
            #"\*.*?\*"#,                           // Italic
            #"`[^`]+`"#,                           // Inline code
            #"~~.*?~~"#,                           // Strikethrough
            #"(?m)^\s*[-*+]\s"#,                   // Unordered lists: -, *, +
            #"(?m)^\s*\d+\.\s"#,                   // Ordered lists: 1., 2.
            #"(?m)^>\s"#,                          // Blockquote
            #"---"#,                               // Horizontal rule
            #"\[.*?\]\(.*?\)"#,                   // Links
            #"(?s)```.*?```"#                      // Multiline code blocks
        ]

        return markdownPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
}

// MARK: - Supporting Structures

struct AnyModifier: ViewModifier {
    private let modifier: (AnyView) -> AnyView
    
    init<Content: View>(modifier: @escaping (Content) -> some View) {
        self.modifier = { anyView in
            AnyView(modifier(anyView as! Content)) // swiftlint:disable:this force_cast
        }
    }
    
    func body(content: Content) -> some View {
        modifier(AnyView(content))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies modifier conditionally
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Adds an iOS version check to the view
    @ViewBuilder func iOSVersionSpecific<T: View, U: View>(
        iOS15: @escaping (Self) -> T,
        iOS16AndAbove: @escaping (Self) -> U
    ) -> some View {
        if #available(iOS 16.0, *) {
            iOS16AndAbove(self)
        } else {
            iOS15(self)
        }
    }
    
    /// Adds a tap gesture that also hides keyboard
    func onTapGestureWithKeyboardHide(count: Int = 1, perform action: @escaping () -> Void) -> some View {
        self.onTapGesture(count: count) {
            AppUtils.hideKeyboard()
            action()
        }
    }
    
    /// Adds rounded corners to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

extension View {
    @ViewBuilder
    func conditionalRefreshable(
        _ condition: Bool,
        action: @Sendable @escaping () -> Void
    ) -> some View {
        if condition {
            self.refreshable(action: action)
        } else {
            self
        }
    }
}


