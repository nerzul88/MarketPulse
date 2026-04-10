//
//  FetchFavoritesUseCase.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

final class FetchFavoritesUseCase {
	private let repository: FavoritesRepositoryProtocol

	init(repository: FavoritesRepositoryProtocol) {
		self.repository = repository
	}

	func execute() throws -> [FavoriteAsset] {
		try repository.fetchFavorites()
	}
}
