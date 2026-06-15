import SwiftUI
import UIKit

@objc(SpotifyReframeConceptHomeControllerFactory)
public final class SpotifyReframeConceptHomeControllerFactory: NSObject {
    @objc public static func makeController() -> UIViewController {
        let controller = UIHostingController(rootView: SpotifyConceptHomeView())
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        return controller
    }
}

