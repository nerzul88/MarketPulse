//
//  FavoritesRepository.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

final class FavoritesRepository: FavoritesRepositoryProtocol {

	private let localStorage: FavoritesLocalStorageProtocol

	init(localStorage: FavoritesLocalStorageProtocol = FavoritesLocalStorage()) {
		self.localStorage = localStorage
	}

	func fetchFavorites() throws -> [FavoriteAsset] {
		try localStorage.fetchFavorites()
	}

	func addToFavorites(asset: Asset) throws {
		try localStorage.saveFavorite(from: asset)
	}

	func removeFromFavorites(id: String) throws {
		try localStorage.removeFavorite(id: id)
	}

	func isFavorite(id: String) throws -> Bool {
		try localStorage.isFavorite(id: id)
	}
}
