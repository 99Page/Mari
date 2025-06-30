//
//  LoginViewController.swift
//  Rim
//
//  Created by 노우영 on 6/25/25.
//

import Foundation
import UIKit
import SwiftUI
import SnapKit
import ComposableArchitecture
import AuthenticationServices
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import Core


/// 로그인 기능을 처리하기 위한 리듀서
///
///
/// [Firebase - Apple로 로그인](https://firebase.google.com/docs/auth/ios/apple?hl=ko)
@Reducer
struct SignInFeature {
    @ObservableState
    struct State: Equatable {
        // Firebase 인증에는 해시되지 않은 값 사용
        var originNonce = ""
        
        // 애플 인증에는 해시된 값 사용
        var hashedNonce = ""
        
        var appleSignIn = RimImageView.State(image: .resource(imageResource: .appleCircleLogo))
        var googleSignIn = RimImageView.State(image: .resource(imageResource: .googleCircleLogo))
    }
    
    enum Action: ViewAction {
        
        case view(UIAction)
        case delegate(Delegate)
        
        enum UIAction: BindableAction {
            case appleLoginSucceeded(identityToken: String)
            case googleLoginSucceeded
            case appleLoginTapped
            case binding(BindingAction<State>)
        }
        
        enum Delegate {
            case signInSucceeded
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    @Dependency(\.nonceGenerator) var nonceGenerator
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.appleLoginSucceeded(identitiyToken)):
                return .run { [nonce = state.originNonce] send in
                    try await accountClient.loginUsingApple(token: identitiyToken, nonce: nonce)
                    await send(.delegate(.signInSucceeded))
                }
                
            case .view(.appleLoginTapped):
                state.originNonce = nonceGenerator.generateNonce(length: 32)
                state.hashedNonce = nonceGenerator.hash(origin: state.originNonce)
                return .none
                
            case .view(.googleLoginSucceeded):
                return .send(.delegate(.signInSucceeded))
                
            case .view(.binding(_)):
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

@ViewAction(for: SignInFeature.self)
class SignInViewController: UIViewController {
    
    let store: StoreOf<SignInFeature>
    
    let appleSignInButton: RimImageView
    let googleSignInButton: RimImageView
    
    init(store: StoreOf<SignInFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.appleSignInButton = RimImageView(state: $binding.appleSignIn)
        self.googleSignInButton = RimImageView(state: $binding.googleSignIn)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        makeConstraint()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        appleSignInButton.configure()
//        googleSignInButton.configure()
    }
    
    private func makeConstraint() {
        view.addSubview(appleSignInButton)
        view.addSubview(googleSignInButton)
        
        appleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.width.height.equalTo(44)
        }
        
        googleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(appleSignInButton.snp.top).offset(-16)
            make.width.height.equalTo(44)
        }
    }
    
    private func setupView() {
        view.backgroundColor = UIColor(resource: .main)

        appleSignInButton.addAction(.touchUpInside({ [weak self] in
            self?.handleAppleSignIn()
        }))
        
        googleSignInButton.addAction(.touchUpInside({ [weak self] in
            self?.handleGoogleSignIn()
        }))
    }
    
    @objc private func handleAppleSignIn() {
        send(.appleLoginTapped)
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = store.hashedNonce
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func handleGoogleSignIn() {
        // https://firebase.google.com/docs/auth/ios/google-signin?hl=ko&_gl=1*1lymcp3*_up*MQ..*_ga*OTE5NTA4MzAxLjE3NTA5ODMyNzE.*_ga_CW55HF8NVT*czE3NTA5ODMyNzEkbzEkZzAkdDE3NTA5ODMyNzEkajYwJGwwJGgw#implement_google_sign-in
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard error == nil else { return }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential)
            self?.send(.googleLoginSucceeded)
        }
    }
}

extension SignInViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            return
        }
        
        send(.appleLoginSucceeded(identityToken: identityTokenString))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("사용자가 애플 로그인을 취소함")
            case .failed:
                print("애플 로그인 실패: 일반적인 오류 발생")
            case .invalidResponse:
                print("애플 로그인 실패: 응답이 유효하지 않음")
            case .notHandled:
                print("애플 로그인 실패: 요청이 처리되지 않음")
            case .unknown:
                print("애플 로그인 실패: 알 수 없는 오류")
            default:
                print("애플 로그인 실패: 처리되지 않은 오류")
            }
        } else {
            print("애플 로그인 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let store = Store(initialState: SignInFeature.State()) {
        SignInFeature()
    }
    
    ViewControllerPreview {
        SignInViewController(store: store)
    }
}
