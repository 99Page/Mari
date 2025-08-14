import UIKit
import FirebaseCore
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        return true
    }

    /// 주석: 빌드 구성(Debug/Release)에 따라 GoogleService-Info.plist를 선택해 Firebase를 초기화합니다.
    private func configureFirebase() {
        // Info.plist(Firebase 설정) 파일 분기 처리
        #if DEBUG
        let fileName = "GoogleService-Info-dev"
        #else
        let fileName = "GoogleService-Info"
        #endif

        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            // 주석: 설정 파일 누락 시 크래시 대신 개발용 어서션으로 알림
            assertionFailure("Firebase 설정 파일을 불러올 수 없습니다: \(fileName).plist")
            return
        }

        FirebaseApp.configure(options: options)
    }
    
    // ✅ SceneDelegate 사용 시 필요
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // https://firebase.google.com/docs/auth/ios/google-signin?hl=ko&_gl=1*1lymcp3*_up*MQ..*_ga*OTE5NTA4MzAxLjE3NTA5ODMyNzE.*_ga_CW55HF8NVT*czE3NTA5ODMyNzEkbzEkZzAkdDE3NTA5ODMyNzEkajYwJGwwJGgw#implement_google_sign-in
        // 구글 로그인 처리 -page, 2025. 06. 27
        return GIDSignIn.sharedInstance.handle(url)
    }
}
