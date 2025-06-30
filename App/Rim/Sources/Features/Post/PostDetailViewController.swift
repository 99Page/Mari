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
        
        init(postID: String) {
            self.postID = postID
            self.image = .init(image: .custom(url: nil))
            self.title = .init(text: "", textColor: .black, typography: .contentTitle, alignment: .natural)
            self.description = .init(text: "", textColor: .black, alignment: .natural)
        }
    }
    
    enum Action: ViewAction {
        
        case setPostDetail(PostDTO)
        case showFetchFailAlert
        case view(UIAction)
        case alert(PresentationAction<AlertAction>)
        case delegate(Delegate)
        
        enum UIAction: BindableAction {
            case viewDidLoad
            case binding(BindingAction<State>)
        }
        
        enum AlertAction {
            case dismissButtonTapped
        }
        
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
                return .run { [id = state.postID] send in
                    let response = try await postClient.fetchPostByID(id: id)
                    await send(.setPostDetail(response))
                } catch: { _, send in
                    await send(.showFetchFailAlert)
                }
                
            case .view(.binding(_)):
                return .none
            
            case let .setPostDetail(post):
                state.image = .init(image: .custom(url: post.imageUrl))
                state.title.text = post.title
                state.description.text = post.content
                return .none
                
            case .alert(.presented(.dismissButtonTapped)):
                return .run { _ in
                    await dismiss()
                }
                
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
    
    init(store: StoreOf<PostDetailFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.titleLabel = RimLabel(state: $binding.title)
        self.descriptionLabel = RimLabel(state: $binding.description)
        self.imageView = RimImageView(state: $binding.image)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeConstraint()
        setupView()
        configureSubviews()
        
        send(.viewDidLoad)
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    private func configureSubviews() {
        titleLabel.configure()
        descriptionLabel.configure()
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
            make.bottom.equalTo(descriptionLabel.snp.bottom)
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
    let store = Store(initialState: PostDetailFeature.State(postID: "")) {
        PostDetailFeature()
    } withDependencies: {
        $0.postClient.fetchPostByID = { _ in
            PostDTO(
                id: "",
                title: "title",
                content: "content",
                imageUrl: "https://picsum.photos/200/300",
                location: .init(latitude: 0, longitude: 0)
            )
        }
    }
    
    
    NavigationStack {
        ViewControllerPreview {
            PostDetailViewController(store: store)
        }
        .ignoresSafeArea()
    }
}

