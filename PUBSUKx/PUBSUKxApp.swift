//
//  PUBSUKxApp.swift
//  PUBSUKx
//
//  Created by John Biddulph on 02/06/2025.
//

import SwiftUI

@main
struct PUBSUKxApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.darkBlue) // or .black, or your custom color
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .white // for bar button items
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
