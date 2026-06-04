//
//  DashboardView.swift
//  ESPA
//
//  Top-level dashboard: 2x2 summary grid + HRI-sorted stockpile list.
//

import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var stockpileVM: StockpileViewModel

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryGrid
                stockpileSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("대시보드")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary cards

    private var summaryGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryCard(title: "총 거점수",
                        value: "\(stockpileVM.stockpiles.count)",
                        subtitle: "전체 모니터링 거점",
                        accent: AppColor.primary)

            SummaryCard(title: "위험 거점수",
                        value: "\(stockpileVM.dangerCount)",
                        subtitle: "긴급 수거 필요",
                        accent: AppColor.danger)

            SummaryCard(title: "평균 HRI",
                        value: Int(stockpileVM.averageHRI).formatted(.number),
                        subtitle: "전체 거점 평균",
                        accent: AppColor.warning)

            SummaryCard(title: "총 봉투수",
                        value: stockpileVM.stockpiles.reduce(0) { $0 + $1.bagCount }.formatted(.number),
                        subtitle: "수거 대기 중",
                        accent: AppColor.primary)
        }
    }

    // MARK: - Stockpile list

    private var stockpileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("거점 우선순위")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(stockpileVM.stockpilesWithHRI.enumerated()), id: \.element.id) { idx, item in
                    StockpileRow(item: item)
                    if idx < stockpileVM.stockpilesWithHRI.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - SummaryCard

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - StockpileRow

struct StockpileRow: View {
    let item: StockpileWithHRI

    var body: some View {
        HStack(spacing: 12) {
            // Priority circle (blue)
            ZStack {
                Circle().fill(AppColor.primary)
                Text("\(item.priority)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text("\(item.bagCount)포대")
                    Text("·")
                    Text("방치 \(item.timeDays)일")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                Text("HRI \(Int(item.hri).formatted(.number))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.riskLevel.color)
                RiskBadge(level: item.riskLevel)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - RiskBadge

struct RiskBadge: View {
    let level: RiskLevel
    var body: some View {
        Text(level.displayName)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(level.color.opacity(0.15))
            .foregroundStyle(level.color)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(StockpileViewModel())
    }
}
