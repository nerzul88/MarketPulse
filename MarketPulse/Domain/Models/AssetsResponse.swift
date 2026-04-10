//
//  AssetsResponse.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import Foundation

struct AssetsResponse: Equatable {
	let assets: [Asset]
	let lastUpdated: Date?
	let isFromCache: Bool
}
