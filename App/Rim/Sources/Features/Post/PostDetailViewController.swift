//
//  PostDetailViewController.swift
//  Rim
//
//  Created by 노우영 on 6/23/25.
//

import Foundation
import ComposableArchitecture
import SnapKit
import SwiftUI
import Core

@Reducer
struct PostDetailFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.blockedUserIds) var blockedUserIds = Set()
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var postMenu: PostMenuFeature.State?
        
        let postID: String
        
        var image: RimImageView.State
        var title: RimLabel.State
        var description: RimLabel.State
        var creatorID: String?
        
        var isProgressViewPresented = false
        var isMenuButtonPresented = false
        var isMyPost = false
        
        init(postID: String) {
            self.postID = postID
            self.image = .init(image: .custom(url: nil))
            self.title = .init(text: "", textColor: .black, typography: .contentTitle, alignment: .natural)
            self.description = .init(text: "", textColor: .black, alignment: .natural)
        }
        
        var menu: [PostMenuFeature.State.Menu] {
            isMyPost ? [.delete] : othersPostMenu
        }
        
        private var othersPostMenu: [PostMenuFeature.State.Menu] {
            isPostBlocked ? [.unblock] : [.block, .report]
        }
        
        var isPostBlocked: Bool {
            guard let creatorID else { return false }
            return blockedUserIds.contains(creatorID)
        }
        
        var navigationColor: UIColor {
            isPostBlocked ? .black : .white
        }
    }
    
    enum Action: ViewAction {
        
        case appendBlockedUserID(String)
        case removeBlockedUserID(String)
        case incrementPostViewCount
        case dismissMenu
        case fetchPostDetail
        case setPostDetail(PostDetailDTO)
        case showFetchFailAlert
        case showAlert(title: String)
        case view(UIAction)
        case alert(PresentationAction<Alert>)
        case postMenu(PresentationAction<PostMenuFeature.Action>)
        case delegate(Delegate)
        case dismissProgress
        
        @CasePathable
        enum UIAction: BindableAction {
            case viewDidLoad
            case binding(BindingAction<State>)
            case menuButtonTapped
        }
        
        @CasePathable
        enum Alert {
            case dismissButtonTapped
            case dismissAlert
        }
        
        @CasePathable
        enum Delegate {
            case dismiss
            case removePostFromMap(id: String)
            case removePostFromMyPosts(id: String)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.postClient) var postClient
    @Dependency(\.userRelationClient) var userRelationClient
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewDidLoad):
                return .merge(
                    .send(.fetchPostDetail),
                    .send(.incrementPostViewCount)
                )
                
            case .view(.menuButtonTapped):
                state.postMenu = .init(activeMenus: state.menu)
                return .none
                
            case .view(.binding(_)):
                return .none
                
            case .incrementPostViewCount:
                return .run { [id = state.postID] send in
                    let _ = try await postClient.incrementPostViewCount(postID: id)
                } catch: { error, send in
                    Logger.error("increment fail: \(error)")
                }
                
            case .fetchPostDetail:
                return .run { [id = state.postID] send in
                    let response = try await postClient.fetchPostByID(id: id)
                    await send(.setPostDetail(response.result))
                } catch: { error, send in
                    await send(.showFetchFailAlert)
                }
            
            case let .setPostDetail(post):
                state.image = .init(image: .custom(url: post.imageUrl))
                state.title.text = post.title
                state.description.text = post.content
                state.isMyPost = post.isMine
                state.creatorID = post.creatorID
                state.isMenuButtonPresented = true
                return .none
                
            case .alert(.presented(.dismissAlert)):
                state.alert = nil
                return .none
                
            case .alert(.presented(.dismissButtonTapped)):
                return .run { _ in
                    await dismiss()
                }

            case .alert(.dismiss):
                return .none
                
            case let .showAlert(title):
                state.alert = AlertState {
                    TextState(title)
                } actions: {
                    ButtonState(role: .cancel, action: .dismissAlert) {
                        TextState("확인")
                    }
                }
                return .none
                
            case .showFetchFailAlert:
                state.alert = AlertState {
                    TextState("게시글을 조회할 수 없어요")
                } actions: {
                    ButtonState(role: .cancel, action: .dismissButtonTapped) {
                        TextState("확인")
                    }
                }
                
                return .none
                
            case .dismissProgress:
                state.isProgressViewPresented = false
                return .none
                
            case .delegate:
                return .none
                
            case .postMenu(.presented(.delegate(.reportPost))):
                return .run { [id = state.postID] send in
                    let response = try await postClient.report(postID: id)
                    await send(.showAlert(title: response.message))
                } catch: { error, send in
                    if let errorResponse = error as? ErrorResponse {
                        await send(.showAlert(title: errorResponse.message))
                    } else {
                        await send(.showAlert(title: "에러가 발생했어요"))
                    }
                }
                
            case .postMenu(.presented(.delegate(.deletePost))):
                state.isProgressViewPresented = true
                
                return .run { [id = state.postID] send in
                    let response = try await postClient.deletePost(postID: id)
                    let id = response.result.id
                    await send(.delegate(.removePostFromMap(id: id)))
                    await send(.delegate(.removePostFromMyPosts(id: id)))
                    await dismiss()
                    await send(.dismissProgress)
                } catch: { _, send in
                    await send(.dismissProgress)
                    await send(.showAlert(title: "게시글을 삭제하지 못했어요"))
                }
                
            case .postMenu(.presented(.delegate(.blocksUser))):
                return .run { [creatorID = state.creatorID] send in
                    let response = try await userRelationClient.blocksUser(userId: creatorID)
                    await send(.appendBlockedUserID(response.result.relationshipId))
                    await send(.dismissMenu)
                } catch: { error, send in
                    if let response = error as? ErrorResponse {
                        
                    } else {
                        
                    }
                }
                
            case .postMenu(.presented(.delegate(.unblocksUser))):
                return .run { [creatorID = state.creatorID] send in
                    let response = try await userRelationClient.unblocksUser(userId: creatorID)
                    await send(.removeBlockedUserID(response.result.relationshipId))
                    await send(.dismissMenu)
                } catch: { error, send in
                    
                }
                
            case .postMenu(_):
                return .none
                
            case let .appendBlockedUserID(id):
                let _ = state.$blockedUserIds.withLock {
                    $0.insert(id)
                }
                return .none
                
            case .dismissMenu:
                state.postMenu = nil
                return .none
                
            case let .removeBlockedUserID(id):
                let _ = state.$blockedUserIds.withLock { $0.remove(id) }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$postMenu, action: \.postMenu) { PostMenuFeature() }
    }
}

@ViewAction(for: PostDetailFeature.self)
class PostDetailViewController: UIViewController {
    
    @UIBindable var store: StoreOf<PostDetailFeature>
    
    private let scrollView = UIScrollView()
    
    private let contentView = UIView()
    private let titleLabel: RimLabel
    private let descriptionLabel: RimLabel
    private let imageView: RimImageView
    
    private var menuButton = UIBarButtonItem()
    
    private let blockedPostView = LegacyBlockedPostView()
    
    init(store: StoreOf<PostDetailFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.titleLabel = RimLabel(state: $binding.title)
        self.descriptionLabel = RimLabel(state: $binding.description)
        self.imageView = RimImageView(state: $binding.image)
        super.init(nibName: nil, bundle: nil)
        
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraint()
        setupView()
        updateView()
        
        send(.viewDidLoad)

        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
        
        present(isPresented: $store.isProgressViewPresented) {
            ProgressViewController()
        }
        
        present(item: $store.scope(state: \.postMenu, action: \.postMenu)) { store in
            let vc = PostMenuViewController(store: store)
            vc.modalPresentationStyle = .pageSheet
            
            if let sheet = vc.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let id = UISheetPresentationController.Detent.Identifier("fitContent")
                    sheet.detents = [
                        .custom(identifier: id) { _ in
                            max(120, vc.preferredContentSize.height) // 최소 높이 가드
                        }
                    ]
                    sheet.selectedDetentIdentifier = id
                    sheet.largestUndimmedDetentIdentifier = id
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                } else {
                    sheet.detents = [.medium()]          // iOS 15 폴백
                    sheet.selectedDetentIdentifier = .medium
                    sheet.largestUndimmedDetentIdentifier = .medium
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                }

                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            return vc
        }
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            
            scrollView.isHidden = store.isPostBlocked
            blockedPostView.isHidden = !store.isPostBlocked
            
            menuButton.isHidden = !store.isMenuButtonPresented
            menuButton.tintColor = store.navigationColor
            navigationController?.navigationBar.tintColor = store.navigationColor
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        setupMenuButton()
    }
    
    private func setupMenuButton() {
        let trashImage = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))
        menuButton = UIBarButtonItem(
            image: trashImage,
            style: .plain,
            target: self,
            action: #selector(didTapMenuButton)
        )
        
        navigationItem.rightBarButtonItem = menuButton
        menuButton.isEnabled = true
        menuButton.tintColor = .white
    }
    
    @objc private func didTapMenuButton() {
        send(.menuButtonTapped)
    }
    
    private func makeConstraint() {
        view.addSubview(scrollView)
        view.addSubview(blockedPostView)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        blockedPostView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.width.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(250)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-32) // 스크롤 content 끝 정의
        }
    }
}

#Preview("fetch fail") {
    let store = Store(initialState: PostDetailFeature.State(postID: "")) {
        PostDetailFeature()
    } withDependencies: {
        $0.postClient.fetchPostByID = { _ in throw ClientError.invalidURL }
    }
    
    
    NavigationStack {
        ViewControllerPreview {
            PostDetailViewController(store: store)
        }
        .ignoresSafeArea()
    }
}

#Preview("fetch success") {
    let stackState = MapNavigationStack.State(postDetail: .init(postID: "postID"))
    let store = Store(initialState: stackState) {
        MapNavigationStack()
    } withDependencies: {
        $0.postClient.fetchPostByID = { _ in .stub() }
    }

    ViewControllerPreview {
        MapNavigationStackController(store: store)
    }
    .ignoresSafeArea()
}

#Preview("for block") {
    let stackState = MapNavigationStack.State(postDetail: .init(postID: "postID"))
    let store = Store(initialState: stackState) {
        MapNavigationStack()
    } withDependencies: {
        let dto = PostDetailDTO(id: "", title: "", content: "", imageUrl: "", location: .init(latitude: 0, longitude: 0), creatorID: "", isMine: false)
        $0.postClient.fetchPostByID = { _ in APIResponse(status: "", message: "", result: dto) }
        $0.userRelationClient.blocksUser = { _ in .stub() }
    }

    ViewControllerPreview {
        MapNavigationStackController(store: store)
    }
    .ignoresSafeArea()
}
