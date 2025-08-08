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
        @Presents var alert: AlertState<Action.AlertAction>?
        @Presents var postMenu: PostMenuFeature.State?
        
        let postID: String
        
        var image: RimImageView.State
        var title: RimLabel.State
        var description: RimLabel.State
        
        var isProgressViewPresented = false
        
        var menu: [PostMenuFeature.State.Menu] = []
        
        init(postID: String) {
            self.postID = postID
            self.image = .init(image: .custom(url: nil))
            self.title = .init(text: "", textColor: .black, typography: .contentTitle, alignment: .natural)
            self.description = .init(text: "", textColor: .black, alignment: .natural)
        }
    }
    
    enum Action: ViewAction {
        
        case incrementPostViewCount
        case fetchPostDetail
        case setPostDetail(PostDetailDTO)
        case showFetchFailAlert
        case showDeleteFailAlert
        case view(UIAction)
        case alert(PresentationAction<AlertAction>)
        case postMenu(PresentationAction<PostMenuFeature.Action>)
        case delegate(Delegate)
        case dismsisProgress
        
        @CasePathable
        enum UIAction: BindableAction {
            case viewDidLoad
            case binding(BindingAction<State>)
            case menuButtonTapped
        }
        
        @CasePathable
        enum AlertAction {
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
                state.menu = post.isMine ? [.delete] : [.block, .report]
                
                Logger.debug("isMine? \(post.isMine)")
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
                
            case .showDeleteFailAlert:
                state.alert = AlertState {
                    TextState("게시글을 삭제하지 못했어요")
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
                
            case .dismsisProgress:
                state.isProgressViewPresented = false
                return .none
                
            case .delegate:
                return .none
                
            case .postMenu(.presented(.delegate(.deletePost))):
                state.isProgressViewPresented = true
                
                return .run { [id = state.postID] send in
                    let response = try await postClient.deletePost(postID: id)
                    let id = response.result.id
                    await send(.delegate(.removePostFromMap(id: id)))
                    await send(.delegate(.removePostFromMyPosts(id: id)))
                    await dismiss()
                    await send(.dismsisProgress)
                } catch: { _, send in
                    await send(.dismsisProgress)
                    await send(.showDeleteFailAlert)
                }
                
            case .postMenu(_):
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
   
    private func setupView() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        let trashImage = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))
        menuButton = UIBarButtonItem(
            image: trashImage,
            style: .plain,
            target: self,
            action: #selector(didTapMenuButton)
        )
        
        navigationItem.rightBarButtonItem = menuButton
        menuButton.tintColor = .clear
        menuButton.isEnabled = true
        menuButton.tintColor = .white
    }
    
    @objc private func didTapMenuButton() {
        send(.menuButtonTapped)
    }
    
    private func makeConstraint() {
        view.addSubview(scrollView)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

