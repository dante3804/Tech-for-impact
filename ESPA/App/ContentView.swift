//
//  ContentView.swift
//  ESPA
//
//  Root TabView wiring the five primary tabs.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("대시보드", systemImage: "house.fill") }

            NavigationStack { MapView() }
                .tabItem { Label("지도", systemImage: "map.fill") }

            NavigationStack { StockpilesView() }
                .tabItem { Label("거점 관리", systemImage: "list.bullet.clipboard.fill") }

            NavigationStack { AnalysisView() }
                .tabItem { Label("사진 분석", systemImage: "camera.fill") }

            NavigationStack { HistoryView() }
                .tabItem { Label("분석 이력", systemImage: "clock.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StockpileViewModel())
        .environmentObject(AnalysisViewModel())
}
