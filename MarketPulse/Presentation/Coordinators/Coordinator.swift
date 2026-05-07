//
//  Coordinator.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 07.05.2026.
//

import UIKit

protocol Coordinator: AnyObject {
	var navigationController: UINavigationController { get }
	func start()
}

class BaseCoordinator: Coordinator {

	let navigationController: UINavigationController

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
	}

	func start() {
		fatalError("Start must be implemented")
	}
}
