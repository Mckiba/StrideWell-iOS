//
//  MainContainerView.swift
//  Stridewell
//
//  M7: TabView with Home | Plan | Chat | Settings.
//  Each tab wraps its content in a NavigationStack for scoped push navigation.
//

import SwiftUI

struct MainContainerView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    HomeScreen()
                }
            }

            Tab("Plan", systemImage: "calendar") {
                NavigationStack {
                    PlanScreen()
                }
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                NavigationStack {
                    ChatStubScreen()
                }
            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsStubScreen()
                }
            }
        }
    }
}
