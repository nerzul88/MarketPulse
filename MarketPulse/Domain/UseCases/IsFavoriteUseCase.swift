//
//  IsFavoriteUseCase.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

final class IsFavoriteUseCase {
	private let repository: FavoritesRepositoryProtocol

	init(repository: FavoritesRepositoryProtocol) {
		self.repository = repository
	}

	func execute(id: String) throws -> Bool {
		try repository.isFavorite(id: id)
	}
}
