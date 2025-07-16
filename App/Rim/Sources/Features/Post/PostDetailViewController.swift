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
        
        let postID: String
        
        var image: RimImageView.State
        var title: RimLabel.State
        var description: RimLabel.State
        var isTrashButtonPresented = false
        
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
        case view(UIAction)
        case alert(PresentationAction<AlertAction>)
        case delegate(Delegate)
        
        @CasePathable
        enum UIAction: BindableAction {
            case viewDidLoad
            case binding(BindingAction<State>)
            case trashButtonTapped
        }
        
        @CasePathable
        enum AlertAction {
            case dismissButtonTapped
            case deleteButtonTapped
            case dismissAlert
        }
        
        @CasePathable
        enum Delegate {
            case dismiss
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
                
            case .view(.trashButtonTapped):
                state.alert = AlertState {
                    TextState("게시물을 삭제할까요? ")
                } actions: {
                    ButtonState(action: .dismissAlert) {
                        TextState("취소")
                    }
                    
                    ButtonState(role: .destructive, action: .deleteButtonTapped) {
                        TextState("삭제")
                    }
                }
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
                    await send(.setPostDetail(response))
                } catch: { _, send in
                    await send(.showFetchFailAlert)
                }
            
            case let .setPostDetail(post):
                state.image = .init(image: .custom(url: post.imageUrl))
                state.title.text = post.title
                state.description.text = post.content
                state.isTrashButtonPresented = post.isMine
                return .none
                
            case .alert(.presented(.dismissAlert)):
                state.alert = nil
                return .none
                
            case .alert(.presented(.dismissButtonTapped)):
                return .run { _ in
                    await dismiss()
                }
                
            case .alert(.presented(.deleteButtonTapped)):
                return .none
                
            case .alert(.dismiss):
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
                
            case .delegate(.dismiss):
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        ._printChanges()
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
    
    private var trashButton = UIBarButtonItem()
    
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
    }
    
    private func updateView() {
        observe { [weak self] in
            guard let self else { return }
            
            trashButton.tintColor = store.isTrashButtonPresented ? .white : .clear
            trashButton.isEnabled = store.isTrashButtonPresented
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        let trashImage = UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))
        trashButton = UIBarButtonItem(
            image: trashImage,
            style: .plain,
            target: self,
            action: #selector(didTapTrashButton)
        )
        
        navigationItem.rightBarButtonItem = trashButton
        trashButton.tintColor = .clear
        trashButton.isEnabled = false
    }
    
    @objc private func didTapTrashButton() {
        send(.trashButtonTapped)
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
        $0.postClient.fetchPostByID = { _ in
            PostDetailDTO(
                id: "",
                title: "title",
                content: "content",
                imageUrl: "https://picsum.photos/200/300",
                location: .init(latitude: 0, longitude: 0),
                isMine: true
            )
        }
    }

    ViewControllerPreview {
        MapNavigationStackController(store: store)
    }
    .ignoresSafeArea()
}

