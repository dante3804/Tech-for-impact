//
//  StockpileViewModel.swift
//  ESPA
//
//  Owns the in-memory list of `Stockpile` records, exposes HRI-enriched
//  derivatives, and provides simple CRUD for the dashboard / map screens.
//

import Foundation
import Combine

@MainActor
final class StockpileViewModel: ObservableObject {

    // MARK: - Published state

    /// Source-of-truth list of raw stockpiles.
    @Published var stockpiles: [Stockpile]

    // MARK: - Init

    /// Defaults to the bundled mock dataset of five coastal sites.
    init(initial: [Stockpile] = MockStockpiles.all) {
        self.stockpiles = initial
    }

    // MARK: - CRUD

    /// Appends a new stockpile. If the id already exists, the call is a no-op.
    func addStockpile(_ stockpile: Stockpile) {
        guard !stockpiles.contains(where: { $0.id == stockpile.id }) else { return }
        stockpiles.append(stockpile)
    }

    /// Replaces the existing stockpile with the same id, if any.
    func updateStockpile(_ stockpile: Stockpile) {
        guard let index = stockpiles.firstIndex(where: { $0.id == stockpile.id }) else { return }
        stockpiles[index] = stockpile
    }

    /// Removes the stockpile with the given id.
    func deleteStockpile(id: Int) {
        stockpiles.removeAll { $0.id == id }
    }

    // MARK: - Derived data

    /// HRI-enriched list, sorted by risk priority (danger first) then HRI desc.
    var stockpilesWithHRI: [StockpileWithHRI] {
        HRICalculator.enrichAndSort(stockpiles)
    }

    /// Number of stockpiles currently classified as `.danger`.
    var dangerCount: Int {
        stockpilesWithHRI.filter { $0.riskLevel == .danger }.count
    }

    /// Number of stockpiles currently classified as `.warning`.
    var warningCount: Int {
        stockpilesWithHRI.filter { $0.riskLevel == .warning }.count
    }

    /// Number of stockpiles currently classified as `.safe`.
    var safeCount: Int {
        stockpilesWithHRI.filter { $0.riskLevel == .safe }.count
    }

    /// Mean HRI across all stockpiles, or 0 when the list is empty.
    var averageHRI: Double {
        guard !stockpiles.isEmpty else { return 0 }
        let total = stockpilesWithHRI.reduce(0.0) { $0 + $1.hri }
        return total / Double(stockpiles.count)
    }

    /// Highest-risk stockpile (first in the sorted, enriched list).
    var topRisk: StockpileWithHRI? {
        stockpilesWithHRI.first
    }

    // MARK: - Lookup helpers

    /// Returns the raw stockpile with the given id, if any.
    func stockpile(id: Int) -> Stockpile? {
        stockpiles.first(where: { $0.id == id })
    }

    /// Returns the enriched record with the given id, if any.
    func enriched(id: Int) -> StockpileWithHRI? {
        stockpilesWithHRI.first(where: { $0.id == id })
    }
}
