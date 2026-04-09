//
//  AssetsListViewController.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import UIKit

final class AssetsListViewController: UIViewController {

	private let viewModel: AssetsListViewModel
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
	private var assets: [Asset] = []

	// MARK: - Init

	init(viewModel: AssetsListViewModel) {
		self.viewModel = viewModel
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
		viewModel.loadAssets()
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

		view.addSubview(tableView)
		view.addSubview(activityIndicator)

		NSLayoutConstraint.activate([
			tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	private func bindViewModel() {
		viewModel.onStateChanged = { [weak self] state in
			self?.handle(state: state)
		}
	}

	private func handle(state: AssetsListViewModel.State) {
		switch state {
		case .loading:
			if assets.isEmpty {
				activityIndicator.startAnimating()
			}
		case .loaded(let assets):
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			self.assets = assets
			tableView.reloadData()
		case .error(let message):
			activityIndicator.stopAnimating()
			refreshControl.endRefreshing()
			showErrorAlert(message: message)
		}
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

	@objc
	private func didPullToRefresh() {
		viewModel.loadAssets()
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

		let repository = AssetRepository(networkClient: NetworkClient())
		let useCase = FetchAssetDetailUseCase(repository: repository)
		let viewModel = AssetDetailViewModel(assetID: asset.id, fetchAssetDetailUseCase: useCase)
		let viewController = AssetDetailViewController(viewModel: viewModel)

		navigationController?.pushViewController(viewController, animated: true)
	}
}
