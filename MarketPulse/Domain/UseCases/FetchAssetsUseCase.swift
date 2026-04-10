//
//  FetchAssetsUseCase.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

final class FetchAssetsUseCase {

	private let repository: AssetRepositoryProtocol

	init(repository: AssetRepositoryProtocol) {
		self.repository = repository
	}

	func execute() async throws -> AssetsResponse {
		try await repository.fetchAssets()
	}
}
