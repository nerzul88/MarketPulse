//
//  AssetsResponse + Mock.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse
import Foundation

extension AssetsResponse {
	static func mock(
		assets: [Asset],
		lastUpdated: Date? = nil,
		isFromCache: Bool = false,
		page: Int = 1,
		canLoadMore: Bool = false
	) -> AssetsResponse {
		AssetsResponse(
			assets: assets,
			lastUpdated: lastUpdated,
			isFromCache: isFromCache,
			page: page,
			canLoadMore: canLoadMore
		)
	}
}
