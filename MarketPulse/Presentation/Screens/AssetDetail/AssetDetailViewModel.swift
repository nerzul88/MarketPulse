//
//  AssetDetailViewModel.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import Foundation

@MainActor
final class AssetDetailViewModel {

	enum State {
		case loading
		case loaded(AssetDetail)
		case error(String)
	}

	private let asset: Asset
	private let fetchAssetDetailUseCase: FetchAssetDetailUseCase
	private let toggleFavoriteUseCase: ToggleFavoriteUseCase
	private let isFavoriteUseCase: IsFavoriteUseCase

	var onStateChanged: ((State) -> Void)?
	var onFavoriteStatusChanged: ((Bool) -> Void)?
	var initialDetail: AssetDetail {
		AssetDetail(
			id: asset.id,
			name: asset.name,
			symbol: asset.symbol,
			price: asset.price,
			change24h: asset.change24h,
			marketCap: nil,
			high24h: nil,
			low24h: nil,
			overview: nil
		)
	}

	init(
		asset: Asset,
		fetchAssetDetailUseCase: FetchAssetDetailUseCase,
		toggleFavoriteUseCase: ToggleFavoriteUseCase,
		isFavoriteUseCase: IsFavoriteUseCase
	) {
		self.asset = asset
		self.fetchAssetDetailUseCase = fetchAssetDetailUseCase
		self.toggleFavoriteUseCase = toggleFavoriteUseCase
		self.isFavoriteUseCase = isFavoriteUseCase
	}

	func load() {
		onStateChanged?(.loading)
		updateFavoriteStatus()

		Task {
			do {
				let detail = try await fetchAssetDetailUseCase.execute(id: asset.id)
				onStateChanged?(.loaded(detail))
			} catch {
				onStateChanged?(.error(error.localizedDescription))
			}
		}
	}

	func updateFavoriteStatus() {
		do {
			let isFavorite = try isFavoriteUseCase.execute(id: asset.id)
			onFavoriteStatusChanged?(isFavorite)
		} catch {
			onFavoriteStatusChanged?(false)
		}
	}

	func toggleFavorite() {
		do {
			let isFavorite = try isFavoriteUseCase.execute(id: asset.id)
			try toggleFavoriteUseCase.execute(asset: asset, isFavorite: isFavorite)
			onFavoriteStatusChanged?(!isFavorite)
		} catch {
			onStateChanged?(.error(error.localizedDescription))
		}
	}
}
