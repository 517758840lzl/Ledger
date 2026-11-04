//
//  SceneDelegate.swift
//  Ledger
//
//  Created by Ketty on 2026/10/12.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let store = LedgerStore()
    private let router = AppRouter()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let root = RootHostView()
            .environmentObject(store)
            .environmentObject(router)
            .tint(AppTheme.greenDark)
        let window = UIWindow(windowScene: windowScene)
        let host = UIHostingController(rootView: root)
        host.view.tintColor = UIColor(AppTheme.greenDark)
        window.tintColor = UIColor(AppTheme.greenDark)
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
    }
}
