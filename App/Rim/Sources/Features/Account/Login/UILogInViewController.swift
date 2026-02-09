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
struct LogInFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.uid) var uid
        @Shared(.isLoggedIn) var isLoggedIn = false
        
        let message: String
        
        // Firebase 인증에는 해시되지 않은 값 사용
        var originNonce = ""
        
        // 애플 인증에는 해시된 값 사용
        var hashedNonce = ""
        
        @Presents var alert: AlertState<AlertAction>?
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        
    }
    
    enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)
        case alert(PresentationAction<AlertAction>)
        case firebaseSignInSucceeded(SignInResult)
        case authenticationSucceeded(uid: String)
        case reportError(context: String, message: String, code: String?)
        
        enum View: BindableAction {
            case appleSignInSucceeded(identityToken: String)
            case signInFailed
            case googleCredentialCreated(credential: AuthCredential)
            case appleSignInTapped
            case binding(BindingAction<State>)
        }
        
        @CasePathable
        enum Delegate {
            case logInSucceeded
            case logInFailed
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    @Dependency(\.nonceGenerator) var nonceGenerator
    @Dependency(\.keychain) var keychain
    @Dependency(\.errorReportClient) var errorReportClient
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.appleSignInSucceeded(identityToken)):
                return .run { [nonce = state.originNonce] send in
                    let signInResult = try await accountClient.signInUsingApple(token: identityToken, nonce: nonce)
                    await send(.firebaseSignInSucceeded(signInResult))
                } catch: { error, send in
                    await send(.view(.signInFailed))
                }
                
            case .view(.appleSignInTapped):
                state.originNonce = nonceGenerator.generateNonce(length: 32)
                state.hashedNonce = nonceGenerator.hash(origin: state.originNonce)
                return .none
                
            case let .view(.googleCredentialCreated(credential)):
                return .run { send in
                    let authData = try await accountClient.signInFirebase(credential: credential)
                    await send(.firebaseSignInSucceeded(authData))
                } catch: { error, send in
                    await send(.reportError(context: "LogIn.signInFirebase", message: String(describing: error), code: nil))
                    await send(.view(.signInFailed))
                }
                
            case .view(.binding(_)):
                return .none
                
            case .view(.signInFailed):
                state.alert = AlertState {
                    TextState("로그인에 실패했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
                return .none
                
            case .delegate:
                return .none
                
            case .alert(_):
                return .none
                
            case let .reportError(context, message, code):
                return .run { _ in
                    try? await errorReportClient.reportError(context, message, code)
                }
                
            case let .firebaseSignInSucceeded(signInResult):
                return .run { send in
                    try keychain.save(value: signInResult.idToken, service: .firebase, account: .idToken)
                    await send(.authenticationSucceeded(uid: signInResult.uid))
                    await send(.delegate(.logInSucceeded))
                }
                
            case let .authenticationSucceeded(uid):
                state.$uid.withLock { $0 = uid }
                state.$isLoggedIn.withLock { $0 = true }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@ViewAction(for: LogInFeature.self)
class UILogInViewController: UIViewController {
    
    @UIBindable var store: StoreOf<LogInFeature>
    
    private let logInLabel: RimLabel
    private let appleLogInButton: RimImageView
    private let googleLogInButton: RimImageView
    private let logInStackView = UIStackView()
    
    init(store: StoreOf<LogInFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.appleLogInButton = RimImageView()
        self.googleLogInButton = RimImageView()
        self.logInLabel = RimLabel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        makeConstraint()
        updateView()
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func updateView() {
        logInLabel.text = .constant(store.message)
        logInLabel.textColor = .constant(.gray)
        logInLabel.typography = .constant(.hint)
        logInLabel.updateView()
        
        appleLogInButton.image = .constant(.resource(imageResource: .appleCircleLogo))
        appleLogInButton.updateView()
        
        googleLogInButton.image = .constant(.resource(imageResource: .googleCircleLogo))
        googleLogInButton.updateView()
    }
    
    private func makeConstraint() {
        let containerView = UIView()
        view.addSubview(containerView)
        
        containerView.addSubview(logInLabel)
        containerView.addSubview(logInStackView)
        
        logInStackView.addArrangedSubview(appleLogInButton)
        logInStackView.addArrangedSubview(googleLogInButton)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            
            // 전체 화면에서는 중앙에 위치하게 하면서
            // 시트 환경에서는 상하 높이를 더함
            make.top.equalToSuperview().offset(40).priority(.low)
            make.bottom.equalToSuperview().offset(-40).priority(.low)
            
            make.top.greaterThanOrEqualToSuperview().offset(40)
            make.bottom.lessThanOrEqualToSuperview().offset(-40)
        }
        
        logInLabel.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        
        logInStackView.snp.makeConstraints { make in
            make.top.equalTo(logInLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview() // ✅ 컨테이너의 바닥을 결정
        }
        
        [appleLogInButton, googleLogInButton].forEach { button in
            button.snp.makeConstraints { make in
                make.width.height.equalTo(44)
            }
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        logInStackView.axis = .horizontal
        logInStackView.distribution = .fillEqually
        logInStackView.spacing = 16

        appleLogInButton.addAction(.touchUpInside({ [weak self] in
            self?.handleAppleSignIn()
        }))
        
        googleLogInButton.addAction(.touchUpInside({ [weak self] in
            self?.handleGoogleSignIn()
        }))
    }
}

// MARK: Sign In with Apple
extension UILogInViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            return
        }
        
        send(.appleSignInSucceeded(identityToken: identityTokenString))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let authError = error as? ASAuthorizationError else { return }
        
        switch authError.code {
        case .canceled:
            break
        case .notHandled:
            break
        default:
            send(.signInFailed)
        }
    }
    
    @objc func handleAppleSignIn() {
        send(.appleSignInTapped)
        
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

// MARK: Sign In with Google
extension UILogInViewController {
    func handleGoogleSignIn() {
        // https://firebase.google.com/docs/auth/ios/google-signin?hl=ko&_gl=1*1lymcp3*_up*MQ..*_ga*OTE5NTA4MzAxLjE3NTA5ODMyNzE.*_ga_CW55HF8NVT*czE3NTA5ODMyNzEkbzEkZzAkdDE3NTA5ODMyNzEkajYwJGwwJGgw#implement_google_sign-in
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            
            guard let self else { return }
            
            handleGoogleSignInError(error)
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                send(.signInFailed)
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            send(.googleCredentialCreated(credential: credential))
        }
    }
    
    private func handleGoogleSignInError(_ error: Error?) {
        guard let error = error as NSError? else { return }
        
        if error.domain == kGIDSignInErrorDomain &&
            error.code == GIDSignInError.canceled.rawValue { // 사용자에 의한 취소
            return
        }
        
        send(.signInFailed)
    }
}

#Preview {
    let store = Store(initialState: LogInFeature.State(message: "로그인하기")) {
        LogInFeature()
    }
    
    ViewControllerPreview {
        UILogInViewController(store: store)
    }
}
