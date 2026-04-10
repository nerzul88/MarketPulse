//
//  ToggleFavoriteUseCase.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

final class ToggleFavoriteUseCase {
	private let repository: FavoritesRepositoryProtocol

	init(repository: FavoritesRepositoryProtocol) {
		self.repository = repository
	}

	func execute(asset: Asset, isFavorite: Bool) throws {
		if isFavorite {
			try repository.removeFromFavorites(id: asset.id)
		} else {
			try repository.addToFavorites(asset: asset)
		}
	}
}
