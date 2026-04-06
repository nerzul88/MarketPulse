//
//  AssetsListViewModel.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import Foundation

final class AssetsListViewModel {

	// MARK: - State

	enum State {
		case loading
		case loaded([Asset])
		case error(String)
	}

	// MARK: - Properties

	private let fetchAssetsUseCase: FetchAssetsUseCase

	var onStateChanged: ((State) -> Void)?

	// MARK: - Init

	init(fetchAssetsUseCase: FetchAssetsUseCase) {
		self.fetchAssetsUseCase = fetchAssetsUseCase
	}

	// MARK: - Actions

	func loadAssets() {
		onStateChanged?(.loading)

		Task {
			do {
				let assets = try await fetchAssetsUseCase.execute()
				await MainActor.run {
					onStateChanged?(.loaded(assets))
				}
			} catch {
				await MainActor.run {
					onStateChanged?(.error(error.localizedDescription))
				}
			}
		}
	}
}
