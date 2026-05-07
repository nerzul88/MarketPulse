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

	func makeAssetsListScreen(
		onAssetSelected: @escaping (Asset) -> Void
	) -> UIViewController {
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: fetchAssetsUseCase)
		return AssetsListViewController(
			viewModel: viewModel,
			onAssetSelected: onAssetSelected
		)
	}

	func makeFavoritesScreen(
		onAssetSelected: @escaping (Asset) -> Void
	) -> UIViewController {
		let viewModel = FavoritesViewModel(fetchFavoritesUseCase: fetchFavoritesUseCase)
		return FavoritesViewController(
			viewModel: viewModel,
			onAssetSelected: onAssetSelected
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
