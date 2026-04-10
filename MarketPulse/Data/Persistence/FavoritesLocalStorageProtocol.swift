//
//  FavoritesLocalStorageProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

protocol FavoritesLocalStorageProtocol {
	func fetchFavorites() throws -> [FavoriteAsset]
	func saveFavorite(from asset: Asset) throws
	func removeFavorite(id: String) throws
	func isFavorite(id: String) throws -> Bool
}
