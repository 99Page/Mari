//
//  PostCell.swift
//  Rim
//
//  Created by 노우영 on 2/10/26.
//

import UIKit
import SnapKit
import Kingfisher
import ComposableArchitecture
import Core

final class PostCell: UITableViewCell {
    
    // MARK: - UI Components
    
    let postImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill // 가로 꽉 채우기
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6 // 로딩 전 회색 배경
        return iv
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        contentView.addSubview(postImageView)
        contentView.addSubview(contentLabel)
        
        postImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(postImageView.snp.width).multipliedBy(1.25)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(postImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-32)
        }
    }
    
    // MARK: - Configure
    
    func configure(with post: PostDetail) {
        contentLabel.text = post.description
        setImage(post.imageURL)
    }
    
    private func setImage(_ urlString: String) {
        
        postImageView.kf.setImage(
            with: URL(string: urlString),
            placeholder: nil,
            options: [
                .transition(.fade(0.2)), // 부드러운 전환
                .cacheOriginalImage
            ]
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        postImageView.image = nil
        contentLabel.text = nil
        postImageView.kf.cancelDownloadTask()
    }
}

#Preview {
    let mockURL = MockImage(width: 1000, height: 1400).urlString
    let store = Store(initialState: PostListFeature.State(imageURL: mockURL)) {
        PostListFeature()
    }
    
    PostListViewController(store: store)
}
