//
//  FavoritesCoordinator.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 07.05.2026.
//

import UIKit

final class FavoritesCoordinator: BaseCoordinator {

	private let appContainer: AppContainer

	init(
		navigationController: UINavigationController,
		appContainer: AppContainer
	) {
		self.appContainer = appContainer
		super.init(navigationController: navigationController)
	}

	override func start() {
		let viewController = appContainer.makeFavoritesScreen { [weak self] asset in
			self?.showAssetDetail(asset)
		}

		navigationController.setViewControllers([viewController], animated: false)
	}

	private func showAssetDetail(_ asset: Asset) {
		let detailViewController = appContainer.makeAssetDetailScreen(asset: asset)
		navigationController.pushViewController(detailViewController, animated: true)
	}
}
