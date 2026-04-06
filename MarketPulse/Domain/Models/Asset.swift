//
//  Asset.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

struct Asset: Equatable {
	let id: String
	let name: String
	let symbol: String
	let price: Double
	let change24h: Double
}
