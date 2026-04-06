//
//  AssetDetailViewModel.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import Foundation

final class AssetDetailViewModel {

	enum State {
		case loading
		case loaded(AssetDetail)
		case error(String)
	}

	private let assetID: String
	private let fetchAssetDetailUseCase: FetchAssetDetailUseCase

	var onStateChanged: ((State) -> Void)?

	init(assetID: String, fetchAssetDetailUseCase: FetchAssetDetailUseCase) {
		self.assetID = assetID
		self.fetchAssetDetailUseCase = fetchAssetDetailUseCase
	}

	func load() {
		onStateChanged?(.loading)

		Task {
			do {
				let detail = try await fetchAssetDetailUseCase.execute(id: assetID)
				await MainActor.run {
					self.onStateChanged?(.loaded(detail))
				}
			} catch {
				await MainActor.run {
					self.onStateChanged?(.error(error.localizedDescription))
				}
			}
		}
	}
}
