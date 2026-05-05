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
	private let pageSize = 20
	private var isLoading = false
	private var isLoadingPage = false
	private var currentPage = 1
	private var canLoadMore = true
	private var allAssets: [Asset] = []
	private var searchTask: Task<Void, Never>?
	private var initialLoadTask: Task<Void, Never>?
	private var paginationTask: Task<Void, Never>?
	private var currentQuery: String = ""
	private var lastUpdated: Date?
	private var isShowingCachedData = false
	private var paginationErrorMessage: String?

	var onStateChanged: ((State) -> Void)?
	var onPaginationStateChanged: ((Bool) -> Void)?
	var onPaginationErrorChanged: ((String?) -> Void)?

	// MARK: - Init

	init(fetchAssetsUseCase: FetchAssetsUseCase) {
		self.fetchAssetsUseCase = fetchAssetsUseCase
	}

	// MARK: - Actions

	func loadAssets() {
		loadInitialAssets()
	}

	func loadInitialAssets() {
		initialLoadTask?.cancel()
		paginationTask?.cancel()
		initialLoadTask = nil
		paginationTask = nil
		isLoading = true
		setPaginationLoading(false)
		setPaginationError(nil)
		currentPage = 1
		canLoadMore = true
		onStateChanged?(.loading)

		initialLoadTask?.cancel()
		initialLoadTask = Task {
			do {
				let response = try await fetchAssetsUseCase.execute(page: 1, limit: pageSize)
				guard !Task.isCancelled else { return }
				self.allAssets = response.assets
				self.lastUpdated = response.lastUpdated
				self.isShowingCachedData = response.isFromCache
				self.currentPage = response.page
				self.canLoadMore = response.canLoadMore && !response.isFromCache
				self.isLoading = false
				self.initialLoadTask = nil
				emitFilteredAssets()
			} catch {
				guard !Task.isCancelled else { return }
				self.isLoading = false
				self.initialLoadTask = nil
				onStateChanged?(.error(error.localizedDescription))
			}
		}
	}

	func loadNextPageIfNeeded(currentAsset: Asset) {
		guard
			currentQuery.isEmpty,
			!isLoading,
			!isLoadingPage,
			canLoadMore,
			shouldLoadNextPage(currentAsset: currentAsset)
		else {
			return
		}
		
		setPaginationLoading(true)
		setPaginationError(nil)

		paginationTask?.cancel()
		paginationTask = Task {
			do {
				let nextPage = currentPage + 1
				let response = try await fetchAssetsUseCase.execute(page: nextPage, limit: pageSize)
				guard !Task.isCancelled else { return }
				self.allAssets.append(contentsOf: response.assets)
				self.lastUpdated = response.lastUpdated
				self.isShowingCachedData = response.isFromCache
				self.currentPage = response.page
				self.canLoadMore = response.canLoadMore && !response.isFromCache
				self.setPaginationLoading(false)
				self.paginationTask = nil
				self.setPaginationError(nil)
				self.emitFilteredAssets()
			} catch {
				guard !Task.isCancelled else { return }
				self.setPaginationLoading(false)
				self.paginationTask = nil
				self.setPaginationError(error.localizedDescription)
			}
		}
	}

	func retryNextPageLoad() {
		guard
			currentQuery.isEmpty,
			!isLoading,
			!isLoadingPage,
			canLoadMore,
			!allAssets.isEmpty
		else {
			return
		}

		loadNextPageIfNeeded(currentAsset: allAssets[allAssets.count - 1])
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

	private func shouldLoadNextPage(currentAsset: Asset) -> Bool {
		guard let currentIndex = allAssets.firstIndex(where: { $0.id == currentAsset.id }) else {
			return false
		}

		let thresholdIndex = max(allAssets.count - 5, 0)
		return currentIndex >= thresholdIndex
	}

	private func setPaginationLoading(_ isLoading: Bool) {
		guard isLoadingPage != isLoading else { return }
		isLoadingPage = isLoading
		onPaginationStateChanged?(isLoading)
	}

	private func setPaginationError(_ message: String?) {
		guard paginationErrorMessage != message else { return }
		paginationErrorMessage = message
		onPaginationErrorChanged?(message)
	}
}
