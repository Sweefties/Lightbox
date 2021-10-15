import UIKit

/// Used to load assets from Lightbox bundle
final class AssetManager {
    
    private static var bundle = Bundle(for: AssetManager.self)
    private static var bundleName = "Lightbox.bundle/"
    
    static func image(_ named: String) -> UIImage? {
        UIImage(named: bundleName.appending(named), in: bundle, compatibleWith: nil)
    }
    
    private static func storyboard(named: String) -> UIStoryboard? {
        UIStoryboard(name: named, bundle: bundle)
    }

    private enum Scene: String {
        case lightbox
    }

    static func viewController() -> LightboxController {
        let identifier = String(describing: LightboxController.self)
        guard
            let scene = storyboard(named: Scene.lightbox.rawValue.capitalized)?
                .instantiateViewController(withIdentifier: identifier) as? LightboxController else {
                    fatalError("\(identifier) failed for instantiate view controller")
                }
        return scene
    }
}

public enum LightBox {
    public static func controller() -> LightboxController {
        AssetManager.viewController()
    }
}
