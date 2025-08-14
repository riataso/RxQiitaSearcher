import UIKit
import RxSwift
import RxCocoa
import SafariServices

class SearchViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = SearchViewModel()

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        title = "Qiita Search"
        view.backgroundColor = .systemBackground

        // SearchBar
        searchBar.placeholder = "記事タイトルを検索"
        navigationItem.titleView = searchBar

        // TableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()

        // Activity Indicator
        activityIndicator.hidesWhenStopped = true

        // Layout
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bindViewModel() {
        // SearchBar → ViewModel
        searchBar.rx.text.orEmpty
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)

        // ViewModel.articles → TableView
        viewModel.articles
            .drive(tableView.rx.items(cellIdentifier: "Cell")) { index, article, cell in
                cell.textLabel?.text = article.title
                cell.detailTextLabel?.text = article.user.id
            }
            .disposed(by: disposeBag)

        // TableView 選択 → ViewModel.itemSelected
        tableView.rx.modelSelected(Article.self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: disposeBag)

        // ViewModel.openArticleURL → Safari表示
        viewModel.openArticleURL
            .drive(onNext: { [weak self] url in
                let safariVC = SFSafariViewController(url: url)
                self?.present(safariVC, animated: true)
            })
            .disposed(by: disposeBag)

        // ViewModel.isLoading → インジケータ表示
        viewModel.isLoading
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        // ViewModel.error → アラート表示
        viewModel.error
            .drive(onNext: { [weak self] apiError in
                let alert = UIAlertController(title: "エラー",
                                              message: apiError.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
