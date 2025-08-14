import Foundation
import RxSwift
import RxCocoa

// アプリケーション全体で使い回す
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです。"
        case .networkError(let error):
            return "ネットワーク接続に問題があります。\n(\(error.localizedDescription))"
        case .decodingError:
            return "データの解析に失敗しました。"
        }
    }
}

protocol QiitaAPIClientProtocol {
    func search(query: String) -> Observable<[Article]>
}

class QiitaAPIClient: QiitaAPIClientProtocol {
    func search(query: String) -> Observable<[Article]> {
        guard !query.isEmpty else {
            return .just([]) // クエリが空なら空配列を返す
        }

        guard var urlComponents = URLComponents(string: "https://qiita.com/api/v2/items") else {
            return .error(APIError.invalidURL)
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: "title:\(query)"),
            URLQueryItem(name: "per_page", value: "20")
        ]

        guard let url = urlComponents.url else {
            return .error(APIError.invalidURL)
        }

        let request = URLRequest(url: url)
        // エラーハンドリングをより詳細に
        return URLSession.shared.rx.data(request: request)
            .map { data -> [Article] in
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode([Article].self, from: data)
                } catch {
                    // デコード失敗時には、decodingErrorを投げる
                    throw APIError.decodingError(error)
                }
            }
            .catch { error in
                // URLSessionのエラーなら、networkErrorを投げる
                return .error(APIError.networkError(error))
            }
    }
}
