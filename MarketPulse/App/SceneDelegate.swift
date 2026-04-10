//
//  SceneDelegate.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else { return }

		let window = UIWindow(windowScene: windowScene)

		let networkClient = NetworkClient()
		let assetsRepository = AssetRepository(networkClient: networkClient)
		let fetchAssetsUseCase = FetchAssetsUseCase(repository: assetsRepository)
		let assetsListViewModel = AssetsListViewModel(fetchAssetsUseCase: fetchAssetsUseCase)
		let assetsListViewController = AssetsListViewController(viewModel: assetsListViewModel)

		let favoritesRepository = FavoritesRepository()
		let fetchFavoritesUseCase = FetchFavoritesUseCase(repository: favoritesRepository)
		let favoritesViewModel = FavoritesViewModel(fetchFavoritesUseCase: fetchFavoritesUseCase)
		let favoritesViewController = FavoritesViewController(viewModel: favoritesViewModel)

		let marketNavController = UINavigationController(rootViewController: assetsListViewController)
		let favoritesNavController = UINavigationController(rootViewController: favoritesViewController)

		marketNavController.tabBarItem = UITabBarItem(
			title: "Market",
			image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
			selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis")
		)

		favoritesNavController.tabBarItem = UITabBarItem(
			title: "Favorites",
			image: UIImage(systemName: "star"),
			selectedImage: UIImage(systemName: "star.fill")
		)

		let tabBarController = UITabBarController()
		tabBarController.viewControllers = [marketNavController, favoritesNavController]

		window.rootViewController = tabBarController
		window.makeKeyAndVisible()
		self.window = window
	}
}

