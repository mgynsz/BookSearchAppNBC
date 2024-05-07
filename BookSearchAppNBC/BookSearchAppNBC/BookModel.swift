//
//  Meta.swift
//  NBCBookStrore
//
//  Created by David Jang on 5/2/24.
//

import Foundation

struct BookModel: Codable {
    let isEnd: Bool
    let pageableCount: Int
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case isEnd = "is_end"
        case pageableCount = "pageable_count"
        case totalCount = "total_count"
    }
}

struct Document: Codable {
    let authors: [String]?
    let contents: String?
    let price: Int?
    let salePrice: Int?
    let thumbnail: String?
    let title: String?
    let datetime: String?
    let isbn: String?
    let publisher: String?
    let translators: [String]?
    let url: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case authors, contents, price, thumbnail, title
        case salePrice = "sale_price"
        case datetime, isbn, publisher, translators, url, status
    }
    
    // RecentBook entity
    init(from recentBook: RecentBook) {
        self.title = recentBook.title
        self.thumbnail = recentBook.thumbnailUrl
        self.authors = recentBook.authors?.components(separatedBy: ", ")
        self.price = Int(recentBook.price)  // 'price'를 Int로 변환
        self.contents = nil
        self.salePrice = nil
        self.datetime = recentBook.dateAdded?.description  // 'dateAdded'를 사용하여 'datetime' 설정
        self.isbn = nil
        self.publisher = nil
        self.translators = nil
        self.url = nil
        self.status = "정보 불러오기 실패"
    }

    
    // SavedBook entity
    init(from savedBook: SavedBook) {
        self.title = savedBook.title
        self.thumbnail = savedBook.thumbnailUrl
        self.authors = savedBook.authors?.components(separatedBy: ", ")
        self.price = Int(savedBook.price)
        self.contents = nil
        self.salePrice = nil
        self.datetime = nil
        self.isbn = nil
        self.publisher = nil
        self.translators = nil
        self.url = nil
        self.status = nil
    }
}

struct SearchResponse: Codable {
    let meta: BookModel
    let documents: [Document]
}
