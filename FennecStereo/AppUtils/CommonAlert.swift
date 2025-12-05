import UIKit
import SwiftUI

class CommonAlert {
    private var alertWindow: UIWindow?

    static let shared = CommonAlert()
    private init() {}

    /// Presents a custom delete confirmation alert with blur and color
    /// - Parameters:
    ///   - title: The alert title (can be nil)
    ///   - message: The alert message (can be nil)
    ///   - cancelTitle: The cancel button title (default: "Cancel")
    ///   - confirmTitle: The confirm button title (default: "Confirm")
    ///   - confirmHandler: Closure called when confirm is tapped
    func show(
        title: String? = nil,
        message: String? = nil,
        cancelTitle: String = "Cancel",
        confirmTitle: String = "Confirm",
        confirmHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

        // Attributed title
        if let title = title{
            let titleAttr = NSAttributedString(string: title, attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.white
            ])
            alert.setValue(titleAttr, forKey: "attributedTitle")
        } else if let title = title {
            alert.title = title
        }

        // Attributed message
        if let message = message {
            let messageAttr = NSAttributedString(string: message, attributes: [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor:UIColor.white
            ])
            alert.setValue(messageAttr, forKey: "attributedMessage")
        } else if let message = message {
            alert.message = message
        }

        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in
            self.alertWindow?.isHidden = true
            self.alertWindow = nil
        })
        cancelAction.setValue(UIColor.systemBlue, forKey: "titleTextColor")

        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            confirmHandler()
            self.alertWindow?.isHidden = true
            self.alertWindow = nil
        }
        confirmAction.setValue(UIColor.systemRed, forKey: "titleTextColor")

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        // Create dark window and present alert
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = UIWindow(windowScene: windowScene!)
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1

        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        window.rootViewController = rootVC
        self.alertWindow = window
        window.makeKeyAndVisible()

        rootVC.present(alert, animated: true)
    }



    /// Finds the top-most UIViewController in the app's window hierarchy
    private static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
} 



extension View {
    @MainActor
    func snapshot(targetSize: CGSize? = nil, scale: CGFloat = 10.0) -> UIImage {

        let content: AnyView = {
            if let targetSize = targetSize {
                return AnyView(
                    self.frame(width: targetSize.width, height: targetSize.height)
                )
            } else {
                return AnyView(self)
            }
        }()

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = false
    
        return renderer.uiImage ?? UIImage()
    }
}

