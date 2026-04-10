//
//  FavoriteAssetEntity.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import CoreData

@objc(FavoriteAssetEntity)
public class FavoriteAssetEntity: NSManagedObject {}

extension FavoriteAssetEntity {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteAssetEntity> {
		NSFetchRequest<FavoriteAssetEntity>(entityName: "FavoriteAsset")
	}

	@NSManaged public var id: String
	@NSManaged public var name: String
	@NSManaged public var symbol: String
	@NSManaged public var price: Double
	@NSManaged public var change24h: Double
	@NSManaged public var savedAt: Date
}
