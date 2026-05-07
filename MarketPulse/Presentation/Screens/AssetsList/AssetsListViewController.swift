//
//  AssetsListViewController.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import UIKit

final class AssetsListViewController: UIViewController {

	private let viewModel: AssetsListViewModel
	private let onAssetSelected: (Asset) -> Void
	private let tableView: UITableView = {
		let tableView = UITableView()
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.rowHeight = 72
		return tableView
	}()
	private let activityIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .large)
		indicator.translatesAutoresizingMaskIntoConstraints = false
		return indicator
	}()
	private let refreshControl = UIRefreshControl()
	private let emptyStateLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = "No assets found"
		label.textAlignment = .center
		label.textColor = .secondaryLabel
		label.isHidden = true
		return label
	}()
	private let searchController: UISearchController = {
		let searchController = UISearchController(searchResultsController: nil)
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "Search by name or symbol"
		return searchController
	}()
	private let statusLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 13)
		label.textColor = .secondaryLabel
		label.textAlignment = .center
		label.numberOfLines = 0
		label.isHidden = true
		return label
	}()
	private let paginationActivityIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .medium)
		indicator.hidesWhenStopped = true
		return indicator
	}()
	private let paginationErrorLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 13)
		label.textColor = .secondaryLabel
		label.textAlignment = .center
		label.numberOfLines = 2
		label.isHidden = true
		return label
	}()
	private let paginationRetryButton: UIButton = {
		var configuration = UIButton.Configuration.plain()
		configuration.title = "Retry"
		let button = UIButton(configuration: configuration)
		button.isHidden = true
		return button
	}()
	private lazy var paginationFooterView: UIView = {
		let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 72))
		paginationActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
		paginationErrorLabel.translatesAutoresizingMaskIntoConstraints = false
		paginationRetryButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(paginationActivityIndicator)
		view.addSubview(paginationErrorLabel)
		view.addSubview(paginationRetryButton)

		NSLayoutConstraint.activate([
			paginationActivityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			paginationActivityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			paginationErrorLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
			paginationErrorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			paginationErrorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
			paginationRetryButton.topAnchor.constraint(equalTo: paginationErrorLabel.bottomAnchor, constant: 4),
			paginationRetryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			paginationRetryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
		])

		return view
	}()
	private var assets: [Asset] = []
	private var isPaginationLoadingVisible = false
	private var paginationErrorMessage: String?

	// MARK: - Init

	init(
		viewModel: AssetsListViewModel,
		onAssetSelected: @escaping (Asset) -> Void
	) {
		self.viewModel = viewModel
		self.onAssetSelected = onAssetSelected
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		bindViewModel()
		viewModel.loadInitialAssets()
	}

	// MARK: - Setup

	private func setupUI() {
		title = "Market"
		view.backgroundColor = .systemBackground

		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(AssetTableViewCell.self, forCellReuseIdentifier: AssetTableViewCell.reuseIdentifier)

		refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
		tableView.refreshControl = refreshControl
		paginationRetryButton.addTarget(self, action: #selector(didTapPaginationRetry), for: .touchUpInside)

		searchController.searchResultsUpdater = self
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		definesPresentationContext = true

		view.addSubview(tableView)
		view.addSubview(activityIndicator)
		view.addSubview(emptyStateLabel)
		view.addSubview(statusLabel)

		NSLayoutConstraint.activate([
			statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
			statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

			tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
			tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

			emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	private func bindViewModel() {
		viewModel.onStateChanged = { [weak self] state in
			self?.handle(state: state)
		}
		viewModel.onPaginationStateChanged = { [weak self] isLoading in
			self?.handlePaginationState(isLoading: isLoading)
		}
		viewModel.onPaginationErrorChanged = { [weak self] message in
			self?.handlePaginationError(message: message)
		}
	}

	private func handle(state: AssetsListViewModel.State) {
		switch state {
		case .loading:
			emptyStateLabel.isHidden = true
			statusLabel.isHidden = assets.isEmpty

			if assets.isEmpty {
				activityIndicator.startAnimating()
				tableView.isHidden = true
			} else {
				activityIndicator.stopAnimating()
				tableView.isHidden = false
			}
		case .loaded(let assets, let lastUpdated, let isFromCache):
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			emptyStateLabel.isHidden = true
			tableView.isHidden = false
			self.assets = assets
			tableView.reloadData()
			updateStatusLabel(lastUpdated: lastUpdated, isFromCache: isFromCache)
		case .empty:
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			handlePaginationError(message: nil)
			assets = []
			tableView.reloadData()
			tableView.isHidden = true
			emptyStateLabel.isHidden = false
			statusLabel.isHidden = true
		case .error(let message):
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			handlePaginationError(message: nil)
			showErrorAlert(message: message)
			statusLabel.isHidden = assets.isEmpty
		}
	}

	private func updateStatusLabel(lastUpdated: Date?, isFromCache: Bool) {
		guard let lastUpdated else {
			statusLabel.isHidden = true
			return
		}

		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short

		let sourceText = isFromCache ? "Showing cached data" : "Updated"
		statusLabel.text = "\(sourceText): \(formatter.string(from: lastUpdated))"
		statusLabel.isHidden = false
	}

	private func showErrorAlert(message: String) {
		guard presentedViewController == nil else { return }

		let alert = UIAlertController(
			title: "Something went wrong",
			message: message,
			preferredStyle: .alert
		)

		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}

	private func handlePaginationState(isLoading: Bool) {
		guard isPaginationLoadingVisible != isLoading else { return }
		isPaginationLoadingVisible = isLoading

		if isLoading, !assets.isEmpty {
			paginationActivityIndicator.startAnimating()
			paginationErrorLabel.isHidden = true
			paginationRetryButton.isHidden = true
			tableView.tableFooterView = paginationFooterView
		} else {
			paginationActivityIndicator.stopAnimating()
			if paginationErrorMessage == nil {
				tableView.tableFooterView = nil
			}
		}
	}

	private func handlePaginationError(message: String?) {
		paginationErrorMessage = message

		guard let message, !assets.isEmpty else {
			paginationErrorLabel.text = nil
			paginationErrorLabel.isHidden = true
			paginationRetryButton.isHidden = true
			if !isPaginationLoadingVisible {
				tableView.tableFooterView = nil
			}
			return
		}

		paginationActivityIndicator.stopAnimating()
		paginationErrorLabel.text = "Couldn't load more assets.\n\(message)"
		paginationErrorLabel.isHidden = false
		paginationRetryButton.isHidden = false
		tableView.tableFooterView = paginationFooterView
	}

	@objc
	private func didPullToRefresh() {
		viewModel.loadInitialAssets()
	}

	@objc
	private func didTapPaginationRetry() {
		viewModel.retryNextPageLoad()
	}
}

// MARK: - UITableViewDataSource

extension AssetsListViewController: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		assets.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: AssetTableViewCell.reuseIdentifier,
			for: indexPath
		) as? AssetTableViewCell else {
			return UITableViewCell()
		}

		let asset = assets[indexPath.row]
		cell.configure(with: asset)
		return cell
	}
}

// MARK: - UITableViewDelegate

extension AssetsListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let asset = assets[indexPath.row]
		onAssetSelected(asset)
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let asset = assets[indexPath.row]
		viewModel.loadNextPageIfNeeded(currentAsset: asset)
	}
}

// MARK: - UISearchResultsUpdating

extension AssetsListViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let query = searchController.searchBar.text ?? ""
		viewModel.search(query: query)
	}
}
