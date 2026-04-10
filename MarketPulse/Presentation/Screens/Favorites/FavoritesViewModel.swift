//
//  FavoritesViewModel.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import Foundation

@MainActor
final class FavoritesViewModel {

	enum State {
		case loaded([FavoriteAsset])
		case empty
		case error(String)
	}

	private let fetchFavoritesUseCase: FetchFavoritesUseCase

	var onStateChanged: ((State) -> Void)?

	init(fetchFavoritesUseCase: FetchFavoritesUseCase) {
		self.fetchFavoritesUseCase = fetchFavoritesUseCase
	}

	func loadFavorites() {
		do {
			let favorites = try fetchFavoritesUseCase.execute()
			onStateChanged?(favorites.isEmpty ? .empty : .loaded(favorites))
		} catch {
			onStateChanged?(.error(error.localizedDescription))
		}
	}
}
