//
//  FavoritesLocalStorage.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import CoreData

final class FavoritesLocalStorage: FavoritesLocalStorageProtocol {

	private let context: NSManagedObjectContext

	init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
		self.context = context
	}

	func fetchFavorites() throws -> [FavoriteAsset] {
		let request = FavoriteAssetEntity.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]

		let objects = try context.fetch(request)

		return objects.map {
			FavoriteAsset(
				id: $0.id,
				name: $0.name,
				symbol: $0.symbol,
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

		try context.save()
	}

	func removeFavorite(id: String) throws {
		let request = FavoriteAssetEntity.fetchRequest()
		request.predicate = NSPredicate(format: "id == %@", id)

		let objects = try context.fetch(request)
		objects.forEach(context.delete)

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
