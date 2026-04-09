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
		case loaded([Asset])
		case empty
		case error(String)
	}

	// MARK: - Properties

	private let fetchAssetsUseCase: FetchAssetsUseCase
	private var isLoading = false
	private var allAssets: [Asset] = []
	private var searchTask: Task<Void, Never>?
	private var currentQuery: String = ""

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
				let assets = try await fetchAssetsUseCase.execute()
				await MainActor.run {
					self.isLoading = false
					self.allAssets = assets
					emitFilteredAssets()
				}
			} catch {
				await MainActor.run {
					self.isLoading = false
					self.onStateChanged?(.error(error.localizedDescription))
				}
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

		onStateChanged?(filteredAssets.isEmpty ? .empty : .loaded(filteredAssets))
	}
}
