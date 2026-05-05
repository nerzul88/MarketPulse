//
//  SceneDelegate.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	private var appContainer: AppContainer?

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else { return }
		let window = UIWindow(windowScene: windowScene)
		let container = AppContainer()
		appContainer = container

		window.rootViewController = container.makeRootViewController()
		window.makeKeyAndVisible()
		self.window = window
	}
}
