//
//  FavoriteAsset.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import Foundation

struct FavoriteAsset: Equatable {
	let id: String
	let name: String
	let symbol: String
	let imageURL: URL?
	let price: Double
	let change24h: Double
	let savedAt: Date
}
