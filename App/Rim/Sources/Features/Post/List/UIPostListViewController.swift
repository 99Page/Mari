//
//  UIPostListViewController.swift
//  Rim
//
//  Created by 노우영 on 2/10/26.
//

import ComposableArchitecture
import Foundation
import UIKit
import Core

@Reducer
struct PostListFeature {
    @ObservableState
    struct State: Equatable {
        var posts = IdentifiedArrayOf<PostDetail>()
        let imageURL: String
    }
    
    enum Action: ViewAction {
        case view(View)
        
        @CasePathable
        enum View: BindableAction {
            case onAppear
            case binding(BindingAction<State>)
        }
    }
    
    @Dependency(\.postClient) var postClient
    @Dependency(\.uuid) var uuid
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.posts = [
                    PostDetail(
                        id: uuid().uuidString,
                        imageURL: state.imageURL,
                        title: "title",
                        location: .init(latitude: 1, longitude: 1),
                        creatorID: "",
                        description: "따분한 나의 눈빛이, 무표정했던 얼굴이 널 보며 빛나고 있어, 널 담은 눈동자는 odd"
                    ),
                    
                    PostDetail(
                        id: uuid().uuidString,
                        imageURL: MockImage(id: uuid(), seed: 3, width: 1000, height: 1400).urlString,
                        title: "title",
                        location: .init(latitude: 1, longitude: 1),
                        creatorID: "",
                        description: "따분한 나의 눈빛이, 무표정했던 얼굴이 널 보며 빛나고 있어, 널 담은 눈동자는 odd"
                    ),
                    
                    PostDetail(
                        id: uuid().uuidString,
                        imageURL: MockImage(id: uuid(), seed: 5, width: 1000, height: 1400).urlString,
                        title: "title",
                        location: .init(latitude: 1, longitude: 1),
                        creatorID: "",
                        description: "따분한 나의 눈빛이, 무표정했던 얼굴이 널 보며 빛나고 있어, 널 담은 눈동자는 odd"
                    ),
                    
                    PostDetail(
                        id: uuid().uuidString,
                        imageURL: MockImage(id: uuid(), seed: 1, width: 1000, height: 1400).urlString,
                        title: "title",
                        location: .init(latitude: 1, longitude: 1),
                        creatorID: "",
                        description: "따분한 나의 눈빛이, 무표정했던 얼굴이 널 보며 빛나고 있어, 널 담은 눈동자는 odd"
                    )
                ]
                return .none
            case .view(.binding):
                return .none
            }
        }
    }
}

@ViewAction(for: PostListFeature.self)
final class PostListViewController: UIViewController {
    
    @UIBindable var store: StoreOf<PostListFeature>
    
    private let tableView: UITableView
    
    init(store: StoreOf<PostListFeature>) {
        @UIBindable var binding = store
        self.store = store
        
        self.tableView = UITableView($binding.posts, cellProvider: { tableView, indexPath, post in
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell
            cell?.configure(with: post)
            cell?.selectionStyle = .none
            return cell
        })
        
        super.init(nibName: nil, bundle: nil)
        
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        makeConstraints()
        send(.onAppear)
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = .leastNonzeroMagnitude
        tableView.estimatedSectionFooterHeight = .leastNonzeroMagnitude
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
    }
    
    private func makeConstraints() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

#Preview {
    let store = Store(initialState: PostListFeature.State(imageURL: MockImage(width: 1000, height: 1400).urlString)) {
        PostListFeature()
    }
    
    PostListViewController(store: store)
}
