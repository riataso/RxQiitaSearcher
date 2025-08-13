import Foundation


struct Article: Codable, Equatable {
    let title: String
    let url: String
    let user: User

    // Equatableに準拠するための実装
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.title == rhs.title && lhs.url == rhs.url && lhs.user == rhs.user
    }
}

struct User: Codable, Equatable {
    let id: String
    let name: String
    let profileImageUrl: String

    // JSONキーとプロパティ名のマッピング
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case profileImageUrl = "profile_image_url"
    }

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id  == rhs.id
    }
}
