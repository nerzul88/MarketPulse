//
//  CachedAssetEntity.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import CoreData

@objc(CachedAssetEntity)
public class CachedAssetEntity: NSManagedObject {}

extension CachedAssetEntity {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<CachedAssetEntity> {
		NSFetchRequest<CachedAssetEntity>(entityName: "CachedAsset")
	}

	@NSManaged public var id: String
	@NSManaged public var name: String
	@NSManaged public var symbol: String
	@NSManaged public var price: Double
	@NSManaged public var change24h: Double
	@NSManaged public var updatedAt: Date
}
