//
//  FetchAssetDetailUseCase.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

final class FetchAssetDetailUseCase {

	private let repository: AssetRepositoryProtocol

	init(repository: AssetRepositoryProtocol) {
		self.repository = repository
	}

	func execute(id: String) async throws -> AssetDetail {
		try await repository.fetchAssetDetail(id: id)
	}
}
