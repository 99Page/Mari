//
//  MyPostViewController.swift
//  Rim
//
//  Created by 노우영 on 7/14/25.
//

import Foundation
import ComposableArchitecture
import UIKit
import SwiftUI
import Core
import RimMacro


@Reducer
struct MyPostFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<AlertAction>?
        var myPosts: IdentifiedArrayOf<MyPost> =  []
        
        // 포스트를 가져오기 위한 커서
        var creationCursor: Date? = Date.now
    }
    
    @CasePathable
    enum AlertAction: Equatable {
        case deletePost(MyPost)
    }
    
    enum Action: ViewAction {
        case delegate(Delegate)
        case removePostFromList(id: String)
        case fetchMyPosts
        case appendPosts(FetchUserPostsResponse)
        case view(UIAction)
        case alert(PresentationAction<AlertAction>)
        case showDeleteConfirmAlert(MyPost)
        case showFetchFailAlert
        case showDeleteFailAlert
        
        @CasePathable
        enum UIAction: BindableAction {
            case binding(BindingAction<State>)
            case deleteButtonTapped(MyPost)
            case didScrollToBottom
            case viewDidLoad
        }
        
        @CasePathable
        enum Delegate {
            case removePostFromMap(id: String)
        }
    }
    
    enum EffetcID {
        case fetchPosts
    }
    
    @Dependency(\.postClient) var postClient
    @Dependency(\.mainQueue) var mainQueue
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce { state, action in
            switch action {
            case .view(.binding):
                return .none
                
            case let .view(.deleteButtonTapped(post)):
                return .send(.showDeleteConfirmAlert(post))
                
            case .view(.didScrollToBottom):
                return .send(.fetchMyPosts)
                
            case .view(.viewDidLoad):
                return .send(.fetchMyPosts)
                
            case .fetchMyPosts:
                guard let cursor = state.creationCursor else { return .none }
                
                return .run { send in
                    let response = try await postClient.fetchUserPosts(lastCreatedAt: cursor).result
                    await send(.appendPosts(response))
                } catch: { error, send in
                    await send(.showFetchFailAlert)
                }
                .throttle(id: EffetcID.fetchPosts, for: .seconds(1), scheduler: self.mainQueue, latest: false)
                
            case .showDeleteFailAlert:
                state.alert = AlertState {
                    TextState("게시물을 삭제하지 못했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
                return .none
                
            case .showFetchFailAlert:
                state.creationCursor = nil
                
                state.alert = AlertState {
                    TextState("게시물을 가져오지 못했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
                return .none
                
            case let .showDeleteConfirmAlert(post):
                state.alert = AlertState {
                    TextState("게시물을 삭제할까요?")
                } actions: {
                    ButtonState(role: .destructive, action: .deletePost(post)) {
                        TextState("삭제")
                    }
                    
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                }
                
                return .none
                
            case let .appendPosts(response):
                let posts = response.posts.map { MyPost(id: $0.id, title: $0.title, section: "main") }
                state.myPosts.append(contentsOf: posts)
                state.creationCursor = response.nextCursor
                return .none
                
            case let .alert(.presented(.deletePost(post))):
                return .run { send in
                    let response = try await postClient.deletePost(postID: post.id)
                    let id = response.result.id
                    await send(.removePostFromList(id: id))
                    await send(.delegate(.removePostFromMap(id: id)))
                } catch: { _, send in
                    await send(.showDeleteFailAlert)
                }
                
            case .alert:
                return .none
                
            case let .removePostFromList(id):
                state.myPosts.remove(id: id)
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@BuildView("view")
@ViewAction(for: MyPostFeature.self)
class MyPostViewController: UIViewController {
    
    @UIBindable var store: StoreOf<MyPostFeature>
    private var previousTintColor: UIColor?
    
    init(store: StoreOf<MyPostFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        addSubviews()
        activateConstraints()
        bind()
        addEvents() 

        send(.viewDidLoad)
        
        present(item: $store.scope(state: \.alert, action: \.alert)) { store in
            UIAlertController(store: store)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousTintColor = navigationController?.navigationBar.tintColor
        navigationController?.navigationBar.tintColor = .black
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = previousTintColor
    }
    
    var bluePrint: UIView {
        RimTableView<MyPostTableViewCell>("myPost") {
            $0.items = self.$store.myPosts
        }
        .constraint(leading: \.leading, trailing: \.trailing, top: \.top, bottom: \.bottom)
        .onRowSelected { indexPath in
            let post = self.store.myPosts[indexPath.row]
            let postDetail = PostDetailFeature.State(postID: post.id)
            self.traitCollection.push(state: AccountNavigationStack.Path.State.postDetail(postDetail))
        }
        .onTrailingSwipe { indexPath in
            let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
                guard let self else { return }
                let post = store.myPosts[indexPath.row]
                send(.deleteButtonTapped(post))
                completionHandler(true)
            }
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        .onPaginated {
            self.send(.didScrollToBottom)
        }
    }
    
    private func setupView() {
        title = "내 게시물"
    }
}

struct MyPost: SectionProvidable {
    let id: String
    let title: String
    var section = "main"
}

class MyPostTableViewCell: UITableViewCell, CellConfigurable {
    typealias Value = MyPost

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with value: UIBinding<Value?>) {
        guard let value = value.wrappedValue else { return }
        var content = defaultContentConfiguration()
        content.text = value.title
        contentConfiguration = content
        
    }
}

#Preview {
    let store = Store(initialState: MyPostFeature.State()) {
        MyPostFeature()
    }
    
    ViewControllerPreview {
        MyPostViewController(store: store)
    }
}
