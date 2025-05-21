import UIKit
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        
        window.rootViewController = viewController // <- 여기에 원하는 VC 넣기
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}
