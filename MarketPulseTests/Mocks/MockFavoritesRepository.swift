//
//  MockFavoritesRepository.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse

final class MockFavoritesRepository: FavoritesRepositoryProtocol {

	var fetchFavoritesResult: Result<[FavoriteAsset], Error>?
	var isFavoriteResult: Result<Bool, Error>?
	var addedAsset: Asset?
	var removedFavoriteID: String?
	var lastIsFavoriteRequestedID: String?
	var fetchFavoritesCallCount = 0

	func fetchFavorites() throws -> [FavoriteAsset] {
		fetchFavoritesCallCount += 1

		guard let fetchFavoritesResult else {
			fatalError("fetchFavoritesResult was not set")
		}

		return try fetchFavoritesResult.get()
	}

	func addToFavorites(asset: Asset) throws {
		addedAsset = asset
	}

	func removeFromFavorites(id: String) throws {
		removedFavoriteID = id
	}

	func isFavorite(id: String) throws -> Bool {
		lastIsFavoriteRequestedID = id

		guard let isFavoriteResult else {
			fatalError("isFavoriteResult was not set")
		}

		return try isFavoriteResult.get()
	}
}
