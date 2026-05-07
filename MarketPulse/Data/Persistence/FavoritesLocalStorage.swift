//
//  FavoritesLocalStorage.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import CoreData

final class FavoritesLocalStorage: FavoritesLocalStorageProtocol {

	private let context: NSManagedObjectContext
	private let userDefaults: UserDefaults

	init(
		context: NSManagedObjectContext = CoreDataStack.shared.viewContext,
		userDefaults: UserDefaults = .standard
	) {
		self.context = context
		self.userDefaults = userDefaults
	}

	func fetchFavorites() throws -> [FavoriteAsset] {
		let request = FavoriteAssetEntity.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]

		let objects = try context.fetch(request)
		let imageURLStringsByID = favoriteImageURLStringsByID()

		return objects.map {
			FavoriteAsset(
				id: $0.id,
				name: $0.name,
				symbol: $0.symbol,
				imageURL: imageURLStringsByID[$0.id].flatMap(URL.init(string:)),
				price: $0.price,
				change24h: $0.change24h,
				savedAt: $0.savedAt
			)
		}
	}

	func saveFavorite(from asset: Asset) throws {
		guard try !isFavorite(id: asset.id) else { return }

		let entity = FavoriteAssetEntity(context: context)
		entity.id = asset.id
		entity.name = asset.name
		entity.symbol = asset.symbol
		entity.price = asset.price
		entity.change24h = asset.change24h
		entity.savedAt = Date()
		saveImageURL(asset.imageURL, for: asset.id)

		try context.save()
	}

	func removeFavorite(id: String) throws {
		let request = FavoriteAssetEntity.fetchRequest()
		request.predicate = NSPredicate(format: "id == %@", id)

		let objects = try context.fetch(request)
		objects.forEach(context.delete)
		removeSavedImageURL(for: id)

		if context.hasChanges {
			try context.save()
		}
	}

	func isFavorite(id: String) throws -> Bool {
		let request = FavoriteAssetEntity.fetchRequest()
		request.predicate = NSPredicate(format: "id == %@", id)
		request.fetchLimit = 1

		let count = try context.count(for: request)
		return count > 0
	}
}

private extension FavoritesLocalStorage {
	var favoriteImageURLsStorageKey: String { "favorite_image_urls_by_id" }

	func favoriteImageURLStringsByID() -> [String: String] {
		userDefaults.dictionary(forKey: favoriteImageURLsStorageKey) as? [String: String] ?? [:]
	}

	func saveImageURL(_ imageURL: URL?, for id: String) {
		var imageURLStringsByID = favoriteImageURLStringsByID()
		imageURLStringsByID[id] = imageURL?.absoluteString
		userDefaults.set(imageURLStringsByID, forKey: favoriteImageURLsStorageKey)
	}

	func removeSavedImageURL(for id: String) {
		var imageURLStringsByID = favoriteImageURLStringsByID()
		imageURLStringsByID[id] = nil
		userDefaults.set(imageURLStringsByID, forKey: favoriteImageURLsStorageKey)
	}
}
