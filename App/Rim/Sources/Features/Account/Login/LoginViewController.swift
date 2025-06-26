//
//  LoginViewController.swift
//  Rim
//
//  Created by 노우영 on 6/25/25.
//

import Foundation
import UIKit
import SwiftUI
import CryptoKit
import SnapKit
import ComposableArchitecture
import AuthenticationServices
import FirebaseAuth


/// 로그인 기능을 처리하기 위한 리듀서
///
///
/// [Firebase - Apple로 로그인](https://firebase.google.com/docs/auth/ios/apple?hl=ko)
@Reducer
struct LoginFeature {
    @ObservableState
    struct State {
        
        // Firebase 인증에는 해시되지 않은 값 사용
        var originNonce = ""
        
        // 애플 인증에는 해시된 값 사용
        var hashedNonce = ""
    }
    
    enum Action: ViewAction {
        
        case view(UIAction)
        case delegate(Delegate)
        
        enum UIAction {
            case appleLoginSuccedded(identityToken: String)
            case appleLoginTapped
        }
        
        enum Delegate {
            case signInSucceeded
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    @Dependency(\.nonceGenerator) var nonceGenerator
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.appleLoginSuccedded(identitiyToken)):
                return .run { [nonce = state.originNonce] send in
                    try await accountClient.loginUsingApple(token: identitiyToken, nonce: nonce)
                    await send(.delegate(.signInSucceeded))
                }
                
            case .view(.appleLoginTapped):
                state.originNonce = nonceGenerator.generateNonce(length: 32)
                state.hashedNonce = nonceGenerator.hash(origin: state.originNonce)
                return .none
                
            case .delegate:
                return .none
            } 
        }
    }
}

@ViewAction(for: LoginFeature.self)
class LoginViewController: UIViewController {
    
    let store: StoreOf<LoginFeature>
    let appleLoginButton = ASAuthorizationAppleIDButton()
    
    init(store: StoreOf<LoginFeature>) {
        self.store = store
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
    
    private func makeConstraint() {
        view.addSubview(appleLoginButton)
        
        appleLoginButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            $0.height.equalTo(50)
            $0.width.equalTo(280)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .white
        appleLoginButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
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
}

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            return
        }
        
        send(.appleLoginSuccedded(identityToken: identityTokenString))
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
            @unknown default:
                print("애플 로그인 실패: 처리되지 않은 오류")
            }
        } else {
            print("애플 로그인 실패: \(error.localizedDescription)")
        }
    }
}
