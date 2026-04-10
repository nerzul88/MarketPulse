//
//  FavoritesRepositoryProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

protocol FavoritesRepositoryProtocol {
	func fetchFavorites() throws -> [FavoriteAsset]
	func addToFavorites(asset: Asset) throws
	func removeFromFavorites(id: String) throws
	func isFavorite(id: String) throws -> Bool
}
