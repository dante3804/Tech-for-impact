//
//  ESPAApp.swift
//  ESPA — 폐어망 모니터링
//
//  App entry point. Initializes KakaoMapsSDK with the key from Info.plist
//  and injects the shared view-models into the SwiftUI environment.
//

import SwiftUI
import KakaoMapsSDK

@main
struct ESPAApp: App {

    @StateObject private var stockpileVM = StockpileViewModel()
    @StateObject private var analysisVM  = AnalysisViewModel()

    init() {
        // Initialize Kakao Maps SDK once at launch using the NATIVE app key.
        // The REST API key (KAKAO_REST_API_KEY) is used separately by KakaoService.
        if let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String,
           !key.isEmpty {
            SDKInitializer.InitSDK(appKey: key)
        } else {
            NSLog("[ESPA] Missing KAKAO_NATIVE_APP_KEY in Info.plist — Map tab will not load.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stockpileVM)
                .environmentObject(analysisVM)
                .tint(AppColor.primary)
        }
    }
}
