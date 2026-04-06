//
//  AssetsListViewController.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import UIKit

final class AssetsListViewController: UIViewController {

	private let viewModel: AssetsListViewModel
	private let tableView = UITableView()
	private let cellIdentifier = "AssetCell"
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

//		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.dataSource = self
		view.addSubview(tableView)

		tableView.frame = view.bounds
	}

	private func bindViewModel() {
		viewModel.onStateChanged = { [weak self] state in
			self?.handle(state: state)
		}
	}

	private func handle(state: AssetsListViewModel.State) {
		switch state {
		case .loading:
			print("Loading...")
		case .loaded(let assets):
			self.assets = assets
			tableView.reloadData()
		case .error(let message):
			print("Error: \(message)")
		}
	}
}

// MARK: - UITableViewDataSource

extension AssetsListViewController: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		assets.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
		let asset = assets[indexPath.row]

		cell.textLabel?.text = "\(asset.symbol) - \(asset.price)"
		cell.detailTextLabel?.text = "24h: \(asset.change24h)"

		return cell
	}
}
