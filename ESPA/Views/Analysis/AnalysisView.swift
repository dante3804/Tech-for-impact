//
//  AnalysisView.swift
//  ESPA
//
//  Image-based analysis tab: pick photo → POST to backend → render
//  weather card, detection grid, HRI delta prediction → optionally save
//  the result as an `AnalysisRecord` to history.
//

import SwiftUI
import UIKit

struct AnalysisView: View {

    @EnvironmentObject var stockpileVM: StockpileViewModel
    @EnvironmentObject var analysisVM: AnalysisViewModel

    // Picker state
    @State private var showSourceSheet = false
    @State private var showLibraryPicker = false
    @State private var showCameraPicker = false

    // Save / toast
    @State private var selectedStockpileID: Int?
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imagePickerArea
                analyzeButton
                if let result = analysisVM.analysisResult {
                    weatherCard(for: result)
                    detectionGrid(for: result)
                    riskSummaryCard(for: result)
                    hriPredictionCard(for: result)
                    saveRecordButton(for: result)
                    modelStatusBadge(for: result)
                }
                if let error = analysisVM.errorMessage {
                    errorCard(error)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("사진 분석")
        .confirmationDialog("이미지 선택", isPresented: $showSourceSheet) {
            Button("카메라로 촬영") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCameraPicker = true
                } else {
                    showLibraryPicker = true
                }
            }
            Button("앨범에서 선택") { showLibraryPicker = true }
            Button("취소", role: .cancel) { }
        }
        .sheet(isPresented: $showLibraryPicker) {
            PhotoLibraryPicker(image: $analysisVM.selectedImage)
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPicker(image: $analysisVM.selectedImage)
                .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            if showToast {
                ToastBanner(message: toastMessage)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Image picker area

    private var imagePickerArea: some View {
        Button {
            showSourceSheet = true
        } label: {
            VStack(spacing: 8) {
                if let image = analysisVM.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColor.primary)
                        Text("사진 선택 또는 촬영")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(.gray.opacity(0.4))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Analyze button

    private var analyzeButton: some View {
        Button {
            Task { await analysisVM.analyze() }
        } label: {
            HStack(spacing: 8) {
                if analysisVM.isAnalyzing {
                    ProgressView().tint(.white)
                }
                Text(analysisVM.isAnalyzing ? "분석 중…" : "분석 시작")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(analysisVM.selectedImage == nil || analysisVM.isAnalyzing)
        .opacity(analysisVM.selectedImage == nil ? 0.5 : 1)
    }

    // MARK: - Weather card

    private func weatherCard(for result: AnalysisResult) -> some View {
        let mock = MockWeather.from(bagCount: result.bagCount)
        return VStack(alignment: .leading, spacing: 6) {
            Text("현장 날씨 (분석 시점)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 0) {
                weatherCell("기온", "\(mock.temperature)°C", icon: "thermometer.medium")
                weatherCell("날씨", mock.condition, icon: weatherIcon(mock.condition))
                weatherCell("풍속", String(format: "%.1f m/s", mock.windSpeed), icon: "wind")
                weatherCell("습도", "\(mock.humidity)%", icon: "humidity.fill")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#DBEAFE"), Color(hex: "#EFF6FF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#BFDBFE"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func weatherCell(_ title: String, _ value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColor.primary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func weatherIcon(_ condition: String) -> String {
        switch condition {
        case "맑음":     return "sun.max.fill"
        case "구름 조금": return "cloud.sun.fill"
        case "흐림":     return "cloud.fill"
        case "안개":     return "cloud.fog.fill"
        case "비":       return "cloud.rain.fill"
        default:        return "cloud.fill"
        }
    }

    // MARK: - Detection grid

    private func detectionGrid(for result: AnalysisResult) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            DetectionCell(title: "봉투수",
                          value: "\(result.bagCount)포대",
                          accent: AppColor.primary)
            DetectionCell(title: "충전율",
                          value: result.fillRateEnum.displayName,
                          accent: result.fillRateEnum == .full ? AppColor.danger : AppColor.warning)
            DetectionCell(title: "신뢰도",
                          value: String(format: "%.0f%%", result.confidence * 100),
                          accent: AppColor.safe)
            DetectionCell(title: "예상 무게",
                          value: String(format: "%.1f kg", result.estimatedMassKg),
                          accent: AppColor.primary)
        }
    }

    // MARK: - HRI prediction card

    private func riskSummaryCard(for result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HRI 분석 결과")
                        .font(.headline)
                    Text(environmentText(result.environment))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(hriLevelText(result.hriLevel))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(hriLevelColor(result.hriLevel))
                    .background(hriLevelColor(result.hriLevel).opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                riskMetric("HRI", String(format: "%.1f", result.hriScore), AppColor.primary)
                riskMetric("환경", environmentShortText(result.environment), AppColor.safe)
                riskMetric("해안선", coastlineText(result.coastlineDistanceM), AppColor.warning)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func riskMetric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hriPredictionCard(for result: AnalysisResult) -> some View {
        let analysisHRI = result.hriScore
        let selected = selectedStockpileID.flatMap { stockpileVM.enriched(id: $0) }
        let currentHRI = selected?.hri ?? 0
        let delta = analysisHRI - currentHRI
        let percent = currentHRI > 0 ? (delta / currentHRI) * 100 : 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("HRI 변화 예측")
                .font(.headline)

            Picker("거점 선택", selection: $selectedStockpileID.animation()) {
                Text("거점 선택").tag(Int?.none)
                ForEach(stockpileVM.stockpilesWithHRI) { item in
                    Text(item.name).tag(Int?.some(item.id))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 16) {
                hriColumn(title: "현재 HRI",
                          value: selected != nil ? Int(currentHRI).formatted(.number) : "—",
                          color: selected?.riskLevel.color ?? .secondary)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.top, 22)

                hriColumn(title: "분석 HRI",
                          value: Int(analysisHRI).formatted(.number),
                          color: AppColor.primary)
            }

            if selected != nil {
                HStack(spacing: 6) {
                    Image(systemName: delta >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    Text("\(delta >= 0 ? "+" : "")\(Int(delta).formatted(.number)) (\(String(format: "%.1f", percent))%)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(delta >= 0 ? AppColor.danger : AppColor.safe)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func hriColumn(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Save record

    private func saveRecordButton(for result: AnalysisResult) -> some View {
        Button {
            saveRecord(for: result)
        } label: {
            HStack {
                Image(systemName: "tray.and.arrow.down.fill")
                Text("기록 저장")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(selectedStockpileID == nil ? Color.gray : AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedStockpileID == nil)
    }

    private func saveRecord(for result: AnalysisResult) {
        guard let id = selectedStockpileID,
              let enriched = stockpileVM.enriched(id: id) else { return }

        let analysisHRI = result.hriScore
        let mock = MockWeather.from(bagCount: result.bagCount)

        let record = AnalysisRecord(
            stockpileName: enriched.name,
            stockpileId: enriched.id,
            bagCount: result.bagCount,
            fillRate: result.fillRateEnum,
            confidence: result.confidence,
            estimatedWeight: result.estimatedMassKg,
            estimatedHRI: analysisHRI,
            previousHRI: enriched.hri,
            weather: AnalysisWeather(
                temperature: mock.temperature,
                condition: mock.condition,
                windSpeed: mock.windSpeed,
                humidity: mock.humidity
            ),
            imageName: "analysis_\(Int(Date().timeIntervalSince1970)).jpg",
            modelStatus: result.modelStatus,
            message: messageFor(modelStatus: result.modelStatus)
        )
        analysisVM.saveRecord(record)
        showToast(message: "분석 기록이 저장되었습니다")
    }

    private func messageFor(modelStatus: String) -> String {
        switch modelStatus.lowercased() {
        case "real": return "YOLO 모델 분석 결과입니다."
        case "mock": return "임시 Mock 분석 결과입니다."
        default:     return modelStatus
        }
    }

    // MARK: - Model status

    private func modelStatusBadge(for result: AnalysisResult) -> some View {
        let isReal = result.modelStatus.lowercased() == "real"
        let bg = isReal ? Color(hex: "#DCFCE7") : Color(hex: "#FEF9C3")
        let fg = isReal ? Color(hex: "#166534") : Color(hex: "#854D0E")
        let text = isReal
            ? "YOLO 모델 분석 결과입니다"
            : "임시 Mock 분석 결과입니다"
        return Text(text)
            .font(.caption.weight(.semibold))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColor.warning)
            Text(message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FEF3C7"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func hriLevelText(_ level: String) -> String {
        switch level.lowercased() {
        case "danger":  return "위험"
        case "warning": return "주의"
        case "safe":    return "안전"
        default:        return level
        }
    }

    private func hriLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "danger":  return AppColor.danger
        case "warning": return AppColor.warning
        case "safe":    return AppColor.safe
        default:        return AppColor.primary
        }
    }

    private func environmentText(_ environment: String) -> String {
        switch environment.lowercased() {
        case "marine": return "해안 인접 적치 환경"
        case "land":   return "내륙 적치 환경"
        default:       return environment
        }
    }

    private func environmentShortText(_ environment: String) -> String {
        switch environment.lowercased() {
        case "marine": return "해안"
        case "land":   return "내륙"
        default:       return environment
        }
    }

    private func coastlineText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    // MARK: - Toast

    private func showToast(message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showToast = false }
        }
    }
}

// MARK: - DetectionCell

private struct DetectionCell: View {
    let title: String
    let value: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

// MARK: - Toast banner

private struct ToastBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColor.safe)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
    }
}

// MARK: - MockWeather

/// Deterministic mock weather derived from `bag_count`.
/// Matches the dashboard's seeded RNG so iOS / web stay consistent.
struct MockWeather: Equatable {
    let temperature: Int
    let condition: String
    let windSpeed: Double
    let humidity: Int

    static let conditions = ["맑음", "구름 조금", "흐림", "안개", "비"]

    static func from(bagCount: Int) -> MockWeather {
        let seed = ((bagCount % 251) + 251) % 251
        let temperature = 8 + (seed % 23)
        let condition   = conditions[seed % conditions.count]
        let wind        = (1.2 + Double(seed % 89) / 10.0)
        let windRounded = (wind * 10).rounded() / 10
        let humidity    = 50 + (seed % 41)
        return MockWeather(
            temperature: temperature,
            condition: condition,
            windSpeed: windRounded,
            humidity: humidity
        )
    }
}

#Preview {
    NavigationStack {
        AnalysisView()
            .environmentObject(StockpileViewModel())
            .environmentObject(AnalysisViewModel())
    }
}
