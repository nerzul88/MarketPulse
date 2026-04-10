//
//  FavoritesViewController.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import UIKit

final class FavoritesViewController: UIViewController {

	private let viewModel: FavoritesViewModel

	private let tableView: UITableView = {
		let tableView = UITableView()
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.rowHeight = 72
		return tableView
	}()
	private let emptyStateLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = "No favorites yet"
		label.textAlignment = .center
		label.textColor = .secondaryLabel
		label.isHidden = true
		return label
	}()

	private var favorites: [FavoriteAsset] = []

	init(viewModel: FavoritesViewModel) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		bindViewModel()
		viewModel.loadFavorites()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.loadFavorites()
	}

	private func setupUI() {
		title = "Favorites"
		view.backgroundColor = .systemBackground

		tableView.delegate = self
		tableView.dataSource = self

		tableView.register(AssetTableViewCell.self, forCellReuseIdentifier: AssetTableViewCell.reuseIdentifier)

		view.addSubview(tableView)
		view.addSubview(emptyStateLabel)

		NSLayoutConstraint.activate([
			tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	private func bindViewModel() {
		viewModel.onStateChanged = { [weak self] state in
			self?.handle(state: state)
		}
	}

	private func handle(state: FavoritesViewModel.State) {
		switch state {
		case .loaded(let favorites):
			self.favorites = favorites
			emptyStateLabel.isHidden = true
			tableView.isHidden = false
			tableView.reloadData()
		case .empty:
			favorites = []
			tableView.reloadData()
			tableView.isHidden = true
			emptyStateLabel.isHidden = false
		case .error(let message):
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
}

extension FavoritesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		favorites.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: AssetTableViewCell.reuseIdentifier,
			for: indexPath
		) as? AssetTableViewCell else {
			return UITableViewCell()
		}

		let favorite = favorites[indexPath.row]

		let asset = Asset(
			id: favorite.id,
			name: favorite.name,
			symbol: favorite.symbol,
			price: favorite.price,
			change24h: favorite.change24h
		)

		cell.configure(with: asset)
		return cell
	}
}

// MARK: - UITableViewDelegate

extension FavoritesViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let favorite = favorites[indexPath.row]

		let asset = Asset(
			id: favorite.id,
			name: favorite.name,
			symbol: favorite.symbol,
			price: favorite.price,
			change24h: favorite.change24h
		)

		let assetRepository = AssetRepository(networkClient: NetworkClient())
		let fetchDetailUseCase = FetchAssetDetailUseCase(repository: assetRepository)

		let favoritesRepository = FavoritesRepository()
		let toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: favoritesRepository)
		let isFavoriteUseCase = IsFavoriteUseCase(repository: favoritesRepository)

		let viewModel = AssetDetailViewModel(
			asset: asset,
			fetchAssetDetailUseCase: fetchDetailUseCase,
			toggleFavoriteUseCase: toggleFavoriteUseCase,
			isFavoriteUseCase: isFavoriteUseCase
		)

		let viewController = AssetDetailViewController(viewModel: viewModel)
		navigationController?.pushViewController(viewController, animated: true)
	}
}
