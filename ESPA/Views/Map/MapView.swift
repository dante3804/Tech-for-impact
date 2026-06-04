//
//  MapView.swift
//  ESPA
//
//  Kakao Maps tab. Renders stockpiles as risk-colored markers with name
//  labels. Tapping a marker shows a SwiftUI bubble overlay; tapping the
//  background dismisses it.
//
//  KakaoMapsSDK note:
//  - SDK is initialized once in `ESPAApp.init()` via `SDKInitializer.InitSDK`.
//  - The marker / POI / bubble flow uses public APIs that have been stable
//    since SDK 2.10. If the API surface changes in your installed version,
//    adjust the highlighted call sites in `KakaoMapCoordinator`.
//

import SwiftUI
import UIKit
import KakaoMapsSDK

// KakaoMapsSDK defines its own `Shape` and `Color` types, which collide with
// SwiftUI's. We disambiguate by importing SwiftUI's versions under aliases
// and using them explicitly in this file.
private typealias SUIShape = SwiftUI.Shape
private typealias SUIColor = SwiftUI.Color

// MARK: - Bubble model

enum BubbleDirection {
    /// Bubble draws below the marker (tail points up).
    case below
    /// Bubble draws above the marker (tail points down).
    case above
}

struct MapMarkerSelection: Equatable {
    let stockpile: StockpileWithHRI
    let screenPoint: CGPoint
    let direction: BubbleDirection

    static func == (lhs: MapMarkerSelection, rhs: MapMarkerSelection) -> Bool {
        lhs.stockpile.id == rhs.stockpile.id &&
        lhs.screenPoint == rhs.screenPoint &&
        lhs.direction == rhs.direction
    }
}

// MARK: - MapView

struct MapView: View {

    @EnvironmentObject var stockpileVM: StockpileViewModel
    @State private var selection: MapMarkerSelection?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                KakaoMapContainer(
                    stockpiles: stockpileVM.stockpilesWithHRI,
                    onMarkerTapped: { stockpile, point in
                        selection = MapMarkerSelection(
                            stockpile: stockpile,
                            screenPoint: point,
                            direction: .below
                        )
                    },
                    onMapTapped: {
                        selection = nil
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                if let s = selection {
                    // Fixed top-anchored bubble (SDK 2.12 doesn't expose
                    // MapPoint→screen conversion for an anchored bubble).
                    MarkerBubbleView(item: s.stockpile, direction: .below)
                        .frame(maxWidth: 280)
                        .position(x: geo.size.width / 2, y: 80)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeOut(duration: 0.15), value: s.stockpile.id)
                        .allowsHitTesting(false)
                }
            }
        }
        .navigationTitle("지도")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - MarkerBubbleView

struct MarkerBubbleView: View {
    let item: StockpileWithHRI
    let direction: BubbleDirection

    var body: some View {
        VStack(spacing: 0) {
            if direction == .below {
                Triangle()
                    .fill(SUIColor.white)
                    .frame(width: 18, height: 10)
                    .shadow(color: SUIColor.black.opacity(0.05), radius: 1, y: -1)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SUIColor.primary)
                    Spacer(minLength: 4)
                    RiskBadge(level: item.riskLevel)
                }
                Divider()
                bubbleRow("HRI 점수", "\(Int(item.hri).formatted(.number))",
                          color: item.riskLevel.color)
                bubbleRow("봉투수",   "\(item.bagCount)포대")
                bubbleRow("방치일수", "\(item.timeDays)일")
                bubbleRow("충전율",   item.fillRate.displayName)
            }
            .padding(12)
            .background(SUIColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: SUIColor.black.opacity(0.15), radius: 8, y: 3)
            if direction == .above {
                Triangle()
                    .fill(SUIColor.white)
                    .rotationEffect(.degrees(180))
                    .frame(width: 18, height: 10)
                    .shadow(color: SUIColor.black.opacity(0.05), radius: 1, y: 1)
            }
        }
    }

    private func bubbleRow(_ label: String, _ value: String, color: SUIColor = .primary) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(SUIColor.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(color)
        }
    }
}

private struct Triangle: SUIShape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - KakaoMapContainer

/// `KMViewContainer` subclass that reports its first non-zero layout to the
/// coordinator. KakaoMapsSDK's `prepareEngine()` refuses to initialize while
/// the container has a zero frame (which is always the case at
/// `makeUIView` time under SwiftUI/UIViewRepresentable), so we defer engine
/// preparation until the container has a real size.
final class ESPAMapHostContainer: KMViewContainer {
    var onFirstLayout: ((CGSize) -> Void)?
    private var didFireFirstLayout = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didFireFirstLayout && bounds.size.width > 0 && bounds.size.height > 0 {
            didFireFirstLayout = true
            onFirstLayout?(bounds.size)
        }
    }
}

struct KakaoMapContainer: UIViewRepresentable {
    var stockpiles: [StockpileWithHRI]
    var onMarkerTapped: (StockpileWithHRI, CGPoint) -> Void
    var onMapTapped: () -> Void

    func makeCoordinator() -> KakaoMapCoordinator {
        KakaoMapCoordinator()
    }

    func makeUIView(context: Context) -> ESPAMapHostContainer {
        let container = ESPAMapHostContainer(frame: .zero)
        context.coordinator.attach(
            to: container,
            stockpiles: stockpiles,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped
        )
        // Defer engine preparation until SwiftUI has given the view a real size.
        container.onFirstLayout = { [coordinator = context.coordinator] _ in
            coordinator.startEngine()
        }
        return container
    }

    func updateUIView(_ uiView: ESPAMapHostContainer, context: Context) {
        context.coordinator.update(
            stockpiles: stockpiles,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped
        )
    }

    static func dismantleUIView(_ uiView: ESPAMapHostContainer, coordinator: KakaoMapCoordinator) {
        coordinator.teardown()
    }
}

// MARK: - KakaoMapCoordinator

final class KakaoMapCoordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {

    static let mapViewName  = "espa_map"
    static let layerID      = "espa_stockpile_layer"

    private weak var container: ESPAMapHostContainer?
    private var controller: KMController?
    private var mapAdded = false
    private var engineStarted = false

    private(set) var stockpiles: [StockpileWithHRI] = []
    private var onMarkerTapped: ((StockpileWithHRI, CGPoint) -> Void)?
    private var onMapTapped: (() -> Void)?

    // MARK: Lifecycle

    func attach(
        to container: ESPAMapHostContainer,
        stockpiles: [StockpileWithHRI],
        onMarkerTapped: @escaping (StockpileWithHRI, CGPoint) -> Void,
        onMapTapped: @escaping () -> Void
    ) {
        self.container = container
        self.stockpiles = stockpiles
        self.onMarkerTapped = onMarkerTapped
        self.onMapTapped = onMapTapped

        let controller = KMController(viewContainer: container)
        controller.delegate = self
        self.controller = controller
        // NOTE: prepareEngine() is deferred to `startEngine()` so we wait
        // until the container has a non-zero size (called from `layoutSubviews`).
    }

    /// Called by `ESPAMapHostContainer` once SwiftUI has given the container
    /// a real (non-zero) size. Safe to call multiple times — guarded.
    func startEngine() {
        guard !engineStarted else { return }
        engineStarted = true
        controller?.prepareEngine()
    }

    func update(
        stockpiles: [StockpileWithHRI],
        onMarkerTapped: @escaping (StockpileWithHRI, CGPoint) -> Void,
        onMapTapped: @escaping () -> Void
    ) {
        self.stockpiles = stockpiles
        self.onMarkerTapped = onMarkerTapped
        self.onMapTapped = onMapTapped
        if mapAdded, let map = currentMap() {
            rebuildPois(on: map)
        }
    }

    func teardown() {
        controller?.pauseEngine()
        controller?.resetEngine()
    }

    // MARK: MapControllerDelegate

    func addViews() {
        let center = MapPoint(longitude: 128.972993, latitude: 35.053775) // 부산 다대포항
        let info = MapviewInfo(
            viewName: Self.mapViewName,
            viewInfoName: "map",
            defaultPosition: center,
            defaultLevel: 7
        )
        controller?.addView(info)
    }

    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        guard let map = controller?.getView(viewName) as? KakaoMap else { return }
        map.eventDelegate = self
        map.viewRect = container?.bounds ?? .zero
        registerStyles(on: map)
        rebuildPois(on: map)
        mapAdded = true
        controller?.activateEngine()
    }

    func addViewFailed(_ viewName: String, viewInfoName: String) {
        // Surface to console; user-facing error UI can be added later.
        NSLog("[ESPA] KakaoMap addViewFailed: \(viewName)")
    }

    func containerDidResized(_ size: CGSize) {
        currentMap()?.viewRect = CGRect(origin: .zero, size: size)
    }

    func authenticationSucceeded() { /* ok */ }
    func authenticationFailed(_ errorCode: Int, desc: String) {
        NSLog("[ESPA] Kakao auth failed (\(errorCode)): \(desc)")
    }

    // MARK: KakaoMapEventDelegate

    func kakaoMapDidTapped(kakaoMap: KakaoMap, point: CGPoint) {
        onMapTapped?()
    }

    func cameraWillMove(kakaoMap: KakaoMap, by: MoveBy) {
        // Dismiss the bubble when the user starts panning the map.
        onMapTapped?()
    }

    /// Called by KakaoMapsSDK whenever a registered POI is tapped.
    /// We don't have a public `MapPoint → CGPoint` API in 2.12.x, so we just
    /// surface the marker selection and let the SwiftUI layer place the
    /// bubble at a fixed location on screen.
    func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {
        let prefix = "stockpile_"
        guard poiID.hasPrefix(prefix),
              let intID = Int(poiID.dropFirst(prefix.count)),
              let stockpile = stockpiles.first(where: { $0.id == intID }) else { return }

        let bounds = container?.bounds ?? .zero
        // Pin near the top of the map so the bubble doesn't cover the marker
        // (it'll always be drawn in `.below` direction by the SwiftUI layer).
        let screenPoint = CGPoint(x: bounds.midX, y: 80)
        onMarkerTapped?(stockpile, screenPoint)
    }

    // MARK: POI styles & data

    private func currentMap() -> KakaoMap? {
        controller?.getView(Self.mapViewName) as? KakaoMap
    }

    private func registerStyles(on map: KakaoMap) {
        let manager = map.getLabelManager()
        let layerOptions = LabelLayerOptions(
            layerID: Self.layerID,
            competitionType: .none,
            competitionUnit: .symbolFirst,
            orderType: .rank,
            zOrder: 5001
        )
        _ = manager.addLabelLayer(option: layerOptions)

        for level in RiskLevel.allCases {
            let icon = MarkerIconRenderer.makeIcon(color: UIColor(level.color))
            let iconStyle = PoiIconStyle(symbol: icon, anchorPoint: CGPoint(x: 0.5, y: 0.5))
            let textLine = PoiTextLineStyle(
                textStyle: TextStyle(
                    fontSize: 13,
                    fontColor: UIColor.label,
                    strokeThickness: 2,
                    strokeColor: UIColor.white
                )
            )
            let textStyle = PoiTextStyle(textLineStyles: [textLine])
            let perLevel = PerLevelPoiStyle(iconStyle: iconStyle, textStyle: textStyle, level: 0)
            let style = PoiStyle(styleID: styleID(for: level), styles: [perLevel])
            manager.addPoiStyle(style)
        }
    }

    private func styleID(for level: RiskLevel) -> String { "espa_poi_\(level.rawValue)" }

    private func rebuildPois(on map: KakaoMap) {
        let manager = map.getLabelManager()
        guard let layer = manager.getLabelLayer(layerID: Self.layerID) else { return }
        layer.clearAllItems()

        for s in stockpiles {
            let options = PoiOptions(styleID: styleID(for: s.riskLevel),
                                     poiID: "stockpile_\(s.id)")
            options.rank = 0
            options.clickable = true
            options.addText(PoiText(text: s.name, styleIndex: 0))
            let position = MapPoint(longitude: s.lng, latitude: s.lat)
            let poi = layer.addPoi(option: options, at: position)
            poi?.show()
            // Marker taps are routed through `poiDidTapped(...)` via
            // `KakaoMapEventDelegate` — no per-POI handler needed.
        }
    }
}

// MARK: - MarkerIconRenderer

private enum MarkerIconRenderer {
    /// Renders a 32×32 white-ringed circle marker tinted with `color`.
    static func makeIcon(color: UIColor, size: CGFloat = 32) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            // Drop shadow
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 2,
                         color: UIColor.black.withAlphaComponent(0.25).cgColor)
            // White outer ring
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 1, y: 1, width: size - 2, height: size - 2))
            // Inner color
            cg.setShadow(offset: .zero, blur: 0, color: nil)
            let inset: CGFloat = 5
            cg.setFillColor(color.cgColor)
            cg.fillEllipse(in: CGRect(x: inset, y: inset,
                                      width: size - 2*inset, height: size - 2*inset))
        }
    }
}

#Preview {
    NavigationStack {
        MapView()
            .environmentObject(StockpileViewModel())
    }
}
