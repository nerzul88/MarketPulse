//
//  AppCoordinator.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 07.05.2026.
//

import UIKit

final class AppCoordinator {

	private let window: UIWindow
	private let appContainer: AppContainer
	private var marketCoordinator: MarketCoordinator?
	private var favoritesCoordinator: FavoritesCoordinator?

	init(
		window: UIWindow,
		appContainer: AppContainer
	) {
		self.window = window
		self.appContainer = appContainer
	}

	func start() {
		let marketNavigationController = UINavigationController()
		let favoritesNavigationController = UINavigationController()

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

		let marketCoordinator = MarketCoordinator(
			navigationController: marketNavigationController,
			appContainer: appContainer
		)
		let favoritesCoordinator = FavoritesCoordinator(
			navigationController: favoritesNavigationController,
			appContainer: appContainer
		)

		self.marketCoordinator = marketCoordinator
		self.favoritesCoordinator = favoritesCoordinator

		marketCoordinator.start()
		favoritesCoordinator.start()

		let tabBarController = UITabBarController()
		tabBarController.viewControllers = [
			marketNavigationController,
			favoritesNavigationController
		]

		window.rootViewController = tabBarController
		window.makeKeyAndVisible()
	}
}
