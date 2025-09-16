//
//  PostTableViewCell.swift
//  Rim
//
//  Created by 노우영 on 9/16/25.
//

import Foundation
import Core
import ComposableArchitecture
import UIKit
import SnapKit

struct PostCell: SectionProvidable {
    let id: String
    var title: String
    var description: String
    let section = "main"
    let isMyPost: Bool
    let isBlokcedPost: Bool
    var image: RimImageView.ImageType
    
    init(postDetailDTO: PostDetailDTO) {
        self.id = postDetailDTO.id
        self.title = postDetailDTO.title
        self.description = postDetailDTO.content
        self.image = .custom(url: postDetailDTO.imageUrl)
        self.isMyPost = postDetailDTO.isMine
        self.isBlokcedPost = false
    }
    
    init(dto: PostSummaryDTO) {
        self.id = dto.id
        self.title = dto.title
        self.description = ""
        self.image = .custom(url: dto.imageUrl)
        self.isMyPost = true
        self.isBlokcedPost = false
    }
}


class PostTableViewCell: UITableViewCell, CellConfigurable, EventEmittingCell {
    typealias Event = CellEvent
    typealias Value = PostCell
    
    private let title = RimLabel()
    private let menu = RimImageView()
    private let postImage = RimImageView()
    private let content = RimLabel()
    
    enum CellEvent {
        case menuButtonTapped(PostCell)
    }
    
    var emit: ((Event) -> Void)? = nil
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        makeConstraints()
        selectionStyle = .none
        accessoryType = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeConstraints() {
        contentView.addSubview(title)
        contentView.addSubview(menu)
        contentView.addSubview(postImage)
        contentView.addSubview(content)
        
        title.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.height.equalTo(24)
        }
        
        menu.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(30)
            make.trailing.equalToSuperview()
            make.width.equalTo(30)
        }
        
        postImage.backgroundColor = .red
        
        postImage.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(660)
        }
        
        content.snp.makeConstraints { make in
            make.top.equalTo(postImage.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func configure(with value: UIBinding<PostCell?>) {
        guard let newBinding = UIBinding(value) else { return }
        title.text = newBinding.title
        title.alignment = .constant(.left)
        title.typography = .constant(.contentTitle)
        title.updateView()
        
        postImage.image = newBinding.image
        postImage.updateView()
        postImage.onImageLoaded = { image in
            let ratio = image.size.height / image.size.width
            
            self.postImage.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.width.equalToSuperview()
                make.top.equalTo(self.title.snp.bottom).offset(10)
                make.height.equalTo(self.contentView.snp.width).multipliedBy(ratio)
            }
            
            self.postImage.layoutIfNeeded()
        }
        
        content.text = newBinding.description
        content.alignment = .constant(.left)
        content.updateView()
        
        menu.image = .constant(.symbol(name: "ellipsis", fgColor: .gray))
        menu.addAction(.touchUpInside({
            self.emit?(.menuButtonTapped(newBinding.wrappedValue))
        }))
        menu.updateView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title.observeToken?.cancel()
        postImage.observeToken?.cancel()
        content.observeToken?.cancel()
    }
    
    private func resetImageConstraint() {
        postImage.snp.remakeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(660)
        }
    }
}

#Preview {
    let cell = PostTableViewCell()
    cell.configure(with: .constant(PostCell(postDetailDTO: .stub())))
    
    return cell
}
