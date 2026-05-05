//
//  AppContainer.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 04.05.2026.
//

import UIKit

final class AppContainer {

	// MARK: - Core

	private let networkClient: NetworkClientProtocol
	private let coreDataStack: CoreDataStack

	// MARK: - Storage

	private lazy var assetsLocalStorage: AssetsLocalStorageProtocol = AssetsLocalStorage(
		context: coreDataStack.viewContext
	)

	private lazy var favoritesLocalStorage: FavoritesLocalStorageProtocol = FavoritesLocalStorage(
		context: coreDataStack.viewContext
	)

	// MARK: - Repositories

	private lazy var assetRepository: AssetRepositoryProtocol = AssetRepository(
		networkClient: networkClient,
		localStorage: assetsLocalStorage
	)

	private lazy var favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository(
		localStorage: favoritesLocalStorage
	)

	// MARK: - Use Cases

	private lazy var fetchAssetsUseCase = FetchAssetsUseCase(repository: assetRepository)
	private lazy var fetchAssetDetailUseCase = FetchAssetDetailUseCase(repository: assetRepository)
	private lazy var fetchFavoritesUseCase = FetchFavoritesUseCase(repository: favoritesRepository)
	private lazy var toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: favoritesRepository)
	private lazy var isFavoriteUseCase = IsFavoriteUseCase(repository: favoritesRepository)

	init(
		networkClient: NetworkClientProtocol = NetworkClient(),
		coreDataStack: CoreDataStack = CoreDataStack.shared
	) {
		self.networkClient = networkClient
		self.coreDataStack = coreDataStack
	}

	// MARK: - Factories

	func makeRootViewController() -> UIViewController {
		let marketNavigationController = UINavigationController(rootViewController: makeAssetsListScreen())
		let favoritesNavigationController = UINavigationController(rootViewController: makeFavoritesScreen())

		marketNavigationController.tabBarItem = UITabBarItem(
			title: "Market",
			image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
			selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis")
		)

		favoritesNavigationController.tabBarItem = UITabBarItem(
			title: "Favorites",
			image: UIImage(systemName: "star"),
			selectedImage: UIImage(systemName: "star.fill")
		)

		let tabBarController = UITabBarController()
		tabBarController.viewControllers = [marketNavigationController, favoritesNavigationController]
		return tabBarController
	}

	func makeAssetsListScreen() -> UIViewController {
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: fetchAssetsUseCase)
		return AssetsListViewController(
			viewModel: viewModel,
			makeAssetDetailViewController: { asset in
				self.makeAssetDetailScreen(asset: asset)
			}
		)
	}

	func makeFavoritesScreen() -> UIViewController {
		let viewModel = FavoritesViewModel(fetchFavoritesUseCase: fetchFavoritesUseCase)
		return FavoritesViewController(
			viewModel: viewModel,
			makeAssetDetailViewController: { asset in
				self.makeAssetDetailScreen(asset: asset)
			}
		)
	}

	func makeAssetDetailScreen(asset: Asset) -> UIViewController {
		let viewModel = AssetDetailViewModel(
			asset: asset,
			fetchAssetDetailUseCase: fetchAssetDetailUseCase,
			toggleFavoriteUseCase: toggleFavoriteUseCase,
			isFavoriteUseCase: isFavoriteUseCase
		)

		return AssetDetailViewController(viewModel: viewModel)
	}
}
