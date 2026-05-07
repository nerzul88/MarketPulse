//
//  AssetsLocalStorage.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import CoreData

final class AssetsLocalStorage: AssetsLocalStorageProtocol {

	private let context: NSManagedObjectContext

	init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
		self.context = context
	}

	func saveAssets(_ assets: [Asset]) throws {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedAsset")
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		try context.execute(deleteRequest)

		let now = Date()

		for asset in assets {
			let entity = CachedAssetEntity(context: context)

			entity.id = asset.id
			entity.name = asset.name
			entity.symbol = asset.symbol
			entity.price = asset.price
			entity.change24h = asset.change24h
			entity.updatedAt = now
		}

		if context.hasChanges {
			try context.save()
		}
	}

	func fetchAssets() throws -> CachedAssets {
		let request = CachedAssetEntity.fetchRequest()
		let objects = try context.fetch(request)

		guard !objects.isEmpty else {
			throw PersistenceError.noCachedData
		}

		let assets = objects.map {
			Asset(
				id: $0.id,
				name: $0.name,
				symbol: $0.symbol,
				imageURL: nil,
				price: $0.price,
				change24h: $0.change24h
			)
		}

		let lastUpdated = objects.map(\.updatedAt).max() ?? Date()
		return CachedAssets(assets: assets, lastUpdated: lastUpdated)
	}
}
