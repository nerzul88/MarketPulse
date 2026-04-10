//
//  AssetsListViewModel.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import Foundation

@MainActor
final class AssetsListViewModel {

	// MARK: - State

	enum State {
		case loading
		case loaded([Asset], lastUpdated: Date?, isFromCache: Bool)
		case empty
		case error(String)
	}

	// MARK: - Properties

	private let fetchAssetsUseCase: FetchAssetsUseCase
	private var isLoading = false
	private var allAssets: [Asset] = []
	private var searchTask: Task<Void, Never>?
	private var currentQuery: String = ""
	private var lastUpdated: Date?
	private var isShowingCachedData = false

	var onStateChanged: ((State) -> Void)?

	// MARK: - Init

	init(fetchAssetsUseCase: FetchAssetsUseCase) {
		self.fetchAssetsUseCase = fetchAssetsUseCase
	}

	// MARK: - Actions

	func loadAssets() {
		guard !isLoading else { return }
		isLoading = true
		onStateChanged?(.loading)

		Task {
			do {
				let response = try await fetchAssetsUseCase.execute()
				self.allAssets = response.assets
				self.lastUpdated = response.lastUpdated
				self.isShowingCachedData = response.isFromCache
				self.isLoading = false
				emitFilteredAssets()
			} catch {
				self.isLoading = false
				onStateChanged?(.error(error.localizedDescription))
			}
		}
	}

	func search(query: String) {
		searchTask?.cancel()

		let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
		currentQuery = trimmedQuery

		searchTask = Task {
			try? await Task.sleep(nanoseconds: 400_000_000)

			guard !Task.isCancelled else { return }

			await MainActor.run {
				self.emitFilteredAssets()
			}
		}
	}

	private func emitFilteredAssets() {
		let filteredAssets: [Asset]

		if currentQuery.isEmpty {
			filteredAssets = allAssets
		} else {
			filteredAssets = allAssets.filter {
				$0.name.localizedCaseInsensitiveContains(currentQuery) ||
				$0.symbol.localizedCaseInsensitiveContains(currentQuery)
			}
		}

		onStateChanged?(
			filteredAssets.isEmpty
			? .empty
			: .loaded(filteredAssets, lastUpdated: lastUpdated, isFromCache: isShowingCachedData)
		)
	}
}
