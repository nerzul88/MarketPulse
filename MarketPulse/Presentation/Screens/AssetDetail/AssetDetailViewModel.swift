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
	private let descriptionRetryDelays: [UInt64] = [
		2_000_000_000,
		4_000_000_000,
		6_000_000_000
	]
	private var loadTask: Task<Void, Never>?
	private var descriptionRetryTask: Task<Void, Never>?

	var onStateChanged: ((State) -> Void)?
	var onFavoriteStatusChanged: ((Bool) -> Void)?
	var onOverviewTextChanged: ((String) -> Void)?
	var initialDetail: AssetDetail {
		AssetDetail(
			id: asset.id,
			name: asset.name,
			symbol: asset.symbol,
			price: asset.price,
			change24h: asset.change24h,
			marketCap: asset.marketCap,
			high24h: asset.high24h,
			low24h: asset.low24h,
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
		loadTask?.cancel()
		descriptionRetryTask?.cancel()
		onStateChanged?(.loading)
		updateFavoriteStatus()
		onOverviewTextChanged?(initialOverviewText)

		loadTask = Task { [weak self] in
			guard let self else { return }
			do {
				let detail = try await fetchAssetDetailUseCase.execute(id: self.asset.id)
				guard !Task.isCancelled else { return }
				onStateChanged?(.loaded(detail))
			} catch {
				guard !Task.isCancelled else { return }
				scheduleDescriptionRetryIfNeeded()
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

	deinit {
		loadTask?.cancel()
		descriptionRetryTask?.cancel()
	}
}

private extension AssetDetailViewModel {
	var initialOverviewText: String {
		if let overview = initialDetail.overview, !overview.isEmpty {
			return overview
		}

		return "Loading description..."
	}

	func scheduleDescriptionRetryIfNeeded() {
		guard initialDetail.overview == nil else { return }

		descriptionRetryTask?.cancel()
		descriptionRetryTask = Task { [weak self] in
			guard let self else { return }

			for delay in descriptionRetryDelays {
				try? await Task.sleep(nanoseconds: delay)
				guard !Task.isCancelled else { return }

				do {
					let detail = try await fetchAssetDetailUseCase.execute(id: asset.id)
					guard !Task.isCancelled else { return }
					onStateChanged?(.loaded(detail))
					return
				} catch {
					continue
				}
			}

			guard !Task.isCancelled else { return }
			onOverviewTextChanged?("Description is temporarily unavailable.")
		}
	}
}
