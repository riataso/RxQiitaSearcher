import Foundation
import RxSwift
import RxCocoa

class SearchViewModel {
    let searchText = BehaviorRelay<String>(value: "")
    let itemSelected = PublishRelay<Article>()

    lazy var articles: Driver<[Article]> = self.createArticlesDriver()
    lazy var isLoading: Driver<Bool> = self._isLoading.asDriver()
    lazy var openArticleURL: Driver<URL> = self.createOpenArticleURLDriver()
    lazy var error: Driver<APIError> = self.errorRelay.asDriver(onErrorDriveWith: .empty())

    private let apiClient: QiitaAPIClientProtocol
    private let disposeBag = DisposeBag()
    private let _isLoading = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<APIError>()

    init(apiClient: QiitaAPIClientProtocol = QiitaAPIClient()) {
        self.apiClient = apiClient
    }

    
    private func createArticlesDriver() -> Driver<[Article]> {
        return searchText
            .asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { [weak self] query -> Observable<[Article]> in
                guard let self = self else { return .empty() }

                guard !query.isEmpty else {
                    return .just([])
                }

                return self.apiClient.search(query: query)
                    .do(onNext: { _ in self._isLoading.accept(false) },
                        onError: { _ in self._isLoading.accept(false) },
                        onSubscribe: { self._isLoading.accept(true) })
                    .catch { error in
                        if let apiError = error as? APIError {
                            self.errorRelay.accept(apiError)
                        }
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])
    }

    private func createOpenArticleURLDriver() -> Driver<URL> {
        return itemSelected
            .compactMap { URL(string: $0.url) }
            .asDriver(onErrorDriveWith: .empty())
    }
}
