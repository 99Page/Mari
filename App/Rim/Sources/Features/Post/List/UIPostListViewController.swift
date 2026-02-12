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
        var posts: IdentifiedArrayOf<PostDetail>
        var zoom: Int
        var cursor: String?
        let selectedPost: MapPostState
        
        init(selectedPost: MapPostState, zoom: Int) {
            @Dependency(\.uuid) var uuid
            
            self.selectedPost = selectedPost
            
            self.posts = [
                PostDetail(
                    id: uuid().uuidString,
                    imageURL: selectedPost.imageURL.isEmpty ? selectedPost.thumbnailURL : selectedPost.imageURL,
                    title: "",
                    location: .init(latitude: 1, longitude: 1),
                    creatorID: "",
                    description: ""
                )
            ]
            
            self.zoom = zoom
        }
    }
    
    enum Action: ViewAction {
        case appendPosts([PostDetailDTO])
        case view(View)
        
        @CasePathable
        enum View: BindableAction {
            case onAppear
            case binding(BindingAction<State>)
        }
    }
    
    @Dependency(\.postClient) var postClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.locationManager) var locationManager
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .appendPosts(array):
                let posts = array.map { PostDetail(dto: $0) }
                state.posts.append(contentsOf: posts)
                return .none
                
            case .view(.onAppear):
                let cursor = state.cursor
                let zoom = state.zoom
                
                return .run { [location = state.selectedPost.location] send in
                    let request = PostRequest.GetNearbyPost(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        zoom: zoom,
                        cursor: cursor
                    )
                    
                    let result = try await postClient.fetchNearbyPosts(request: request).result
                    await send(.appendPosts(result.posts))
                } catch: { error, send in
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("🔍 [디코딩 에러] 찾는 키가 없음: '\(key.stringValue)'")
                            print("   경로: \(context.codingPath.map { $0.stringValue })")
                        case .valueNotFound(let type, let context):
                            print("🔍 [디코딩 에러] 값이 null임 (타입: \(type))")
                            print("   경로: \(context.codingPath.map { $0.stringValue })")
                        case .typeMismatch(let type, let context):
                            print("🔍 [디코딩 에러] 타입 불일치 (기대: \(type))")
                            print("   경로: \(context.codingPath.map { $0.stringValue })")
                        default:
                            print("🔍 [디코딩 에러] 기타: \(error)")
                        }
                    } else {
                        Logger.error("일반 에러: \(error.localizedDescription)")
                    }
                }
            case .view(.binding):
                return .none
            }
        }
        ._printChanges()
    }
}

@ViewAction(for: PostListFeature.self)
final class PostListViewController: UIViewController {
    
    @UIBindable var store: StoreOf<PostListFeature>
    
    private let tableView: UITableView
    
    private let heroImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground // 이미지가 없을 때 배경색
        return imageView
    }()
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        heroImageView.removeFromSuperview()
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
        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
    }
    
    private func makeConstraints() {
        view.addSubview(tableView)
        view.addSubview(heroImageView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

#Preview {
    let store = Store(initialState: PostListFeature.State(selectedPost: .stub(), zoom: 17)) {
        PostListFeature()
    }
    
    PostListViewController(store: store)
}
