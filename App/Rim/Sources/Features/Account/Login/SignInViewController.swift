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
        @Shared(.uid) var uid
        
        // Firebase 인증에는 해시되지 않은 값 사용
        var originNonce = ""
        
        // 애플 인증에는 해시된 값 사용
        var hashedNonce = ""
        
        var rimLogo = RimImageView.State(image: .resource(imageResource: .rimWithBackground))
        var signInLabel = RimLabel.State(text: "로그인하기", textColor: UIColor(.gray), typography: .hint)
        var appleSignIn = RimImageView.State(image: .resource(imageResource: .appleCircleLogo))
        var googleSignIn = RimImageView.State(image: .resource(imageResource: .googleCircleLogo))
        
        var isProgressPresented = false
        
        @Presents var alert: AlertState<AlertAction>?
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        
    }
    
    enum Action: ViewAction {
        case view(UIAction)
        case delegate(Delegate)
        case dismissProgressView
        case alert(PresentationAction<AlertAction>)
        case firebaseSignInSucceeded(SignInResult)
        case saveUID(uid: String)
        
        enum UIAction: BindableAction {
            case appleSignInSucceeded(identityToken: String)
            case signInFailed
            case googleCredentialCreated(credential: AuthCredential)
            case appleSignInTapped
            case binding(BindingAction<State>)
        }
        
        @CasePathable
        enum Delegate {
            case signInSucceeded
        }
    }
    
    @Dependency(\.accountClient) var accountClient
    @Dependency(\.nonceGenerator) var nonceGenerator
    @Dependency(\.keychain) var keychain
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.appleSignInSucceeded(identitiyToken)):
                state.isProgressPresented = true
                return .run { [nonce = state.originNonce] send in
                    let signInResult = try await accountClient.signInUsingApple(token: identitiyToken, nonce: nonce)
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
                
            case .dismissProgressView:
                state.isProgressPresented = false
                return .none
                
            case .alert(_):
                return .none
                
            case let .firebaseSignInSucceeded(signInResult):
                return .run { send in
                    try keychain.save(value: signInResult.idToken, service: .firebase, account: .idToken)
                    await send(.saveUID(uid: signInResult.uid))
                    await send(.dismissProgressView)
                    await send(.delegate(.signInSucceeded))
                }
                
            case let .saveUID(uid):
                state.$uid.withLock { $0 = uid }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@ViewAction(for: SignInFeature.self)
class SignInViewController: UIViewController {
    
    @UIBindable var store: StoreOf<SignInFeature>
    
    private let rimLogoImageView: RimImageView
    private let signInLabel: RimLabel
    private let appleSignInButton: RimImageView
    private let googleSignInButton: RimImageView
    private let signInStackView = UIStackView()
    
    init(store: StoreOf<SignInFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.appleSignInButton = RimImageView(state: $binding.appleSignIn)
        self.googleSignInButton = RimImageView(state: $binding.googleSignIn)
        self.signInLabel = RimLabel(state: $binding.signInLabel)
        self.rimLogoImageView = RimImageView(state: $binding.rimLogo)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        makeConstraint()
        
        present(isPresented: $store.isProgressPresented) {
            ProgressViewController()
        }
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func makeConstraint() {
        view.addSubview(rimLogoImageView)
        view.addSubview(signInLabel)
        view.addSubview(signInStackView)
        
        signInStackView.addArrangedSubview(appleSignInButton)
        signInStackView.addArrangedSubview(googleSignInButton)
        
        rimLogoImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(128)
        }
        
        signInLabel.snp.makeConstraints { make in
            make.bottom.equalTo(signInStackView.snp.top).offset(-24)
            make.centerX.equalToSuperview()
        }
        
        signInStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
        }
        
        appleSignInButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
        
        googleSignInButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        signInStackView.axis = .horizontal
        signInStackView.distribution = .fillEqually
        signInStackView.spacing = 16

        appleSignInButton.addAction(.touchUpInside({ [weak self] in
            self?.handleAppleSignIn()
        }))
        
        googleSignInButton.addAction(.touchUpInside({ [weak self] in
            self?.handleGoogleSignIn()
        }))
    }
}

// MARK: Sign In with Apple
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
extension SignInViewController {
    func handleGoogleSignIn() {
        // https://firebase.google.com/docs/auth/ios/google-signin?hl=ko&_gl=1*1lymcp3*_up*MQ..*_ga*OTE5NTA4MzAxLjE3NTA5ODMyNzE.*_ga_CW55HF8NVT*czE3NTA5ODMyNzEkbzEkZzAkdDE3NTA5ODMyNzEkajYwJGwwJGgw#implement_google_sign-in
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        store.isProgressPresented = true
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            
            guard error == nil else {
                self?.send(.signInFailed)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.store.isProgressPresented = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            self?.send(.googleCredentialCreated(credential: credential))
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
