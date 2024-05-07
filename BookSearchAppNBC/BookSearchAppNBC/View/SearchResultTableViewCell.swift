//
//  SearchResultTableViewCell.swift
//  NBCBookStrore
//
//  Created by David Jang on 5/1/24.
//

import UIKit
import SnapKit

class SearchResultTableViewCell: UITableViewCell {

    static let identifier = "SearchResultTableViewCell"

    private let bookImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.tintColor = .lightGray
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .darkGray
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .gray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(priceLabel)
        
        bookImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(120)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(bookImageView.snp.top).offset(8)
            make.left.equalTo(bookImageView.snp.right).offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(bookImageView.snp.right).offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(32)
            make.left.equalTo(bookImageView.snp.right).offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }
    
    func configure(with document: Document) {
        
        // 제목, 썸네일 이미지 설정
        titleLabel.text = document.title ?? "제목 없음"
        bookImageView.sd_setImage(with: URL(string: document.thumbnail ?? ""), placeholderImage: UIImage(named: "placeholderImage"))
        
        // 작가 정보 처리
        if let authors = document.authors, !authors.isEmpty {
            authorLabel.text = authors.joined(separator: ", ")
        } else {
            authorLabel.text = "저자 정보 없음"
        }
        
        // 가격 정보 처리
        if let price = document.price {
            let formattedPrice = Formatter.withSeparator.string(from: NSNumber(value: price)) ?? "\(price)"
            priceLabel.text = formattedPrice + "원"
        } else {
            priceLabel.text = "가격 정보 없음"
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundColor = selected ? UIColor.clear : UIColor.white
    }
}

