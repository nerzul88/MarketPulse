//
//  NetworkConfiguration.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 29.03.2026.
//

struct NetworkConfiguration {
	let baseURL: String
}

extension NetworkConfiguration {
	static let `default` = NetworkConfiguration(
		baseURL: "https://api.coingecko.com/api/v3"
	)
}
