//
//  AppDelegate.swift
//  appdb
//
//  Created by ned on 10/10/2016.
//  Copyright © 2016 ned. All rights reserved.
//

import UIKit
import SwiftTheme
import AlamofireNetworkActivityIndicator
import WidgetKit
import TelemetryClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?

    func applicationWillTerminate(_ application: UIApplication) {
        IPAFileManager.shared.clearTmpDirectory()

        // If there are any queued apps still pending, add them to UserDefaults
        for app in ObserveQueuedApps.shared.requestedApps where !Preferences.resumeQueuedApps.contains(app) {
            Preferences.append(.resumeQueuedApps, element: app)
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TabBarController()
        window?.makeKeyAndVisible()

        // Global Operations
        Global.deleteEventualKeychainData()
        Global.restoreLanguage()
        Themes.restoreLastTheme()
        Global.refreshAppearanceForCurrentTheme()

        // Set main tint color
        self.window?.theme_backgroundColor = Color.tableViewBackgroundColor
        self.window?.theme_tintColor = Color.mainTint

        // Theme Status Bar
        if #available(iOS 13.0, *) {
            application.theme_setStatusBarStyle([.darkContent, .lightContent, .lightContent], animated: true)
        } else {
            application.theme_setStatusBarStyle([.default, .lightContent, .lightContent], animated: true)
        }

        // Theme navigation bar
        let navigationBar = UINavigationBar.appearance()
        let titleAttributes = Color.navigationBarTextColor.map { hexString in
            [
                AttributedStringKey.foregroundColor: UIColor(rgba: hexString),
                AttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16.5)
            ]
        }
        navigationBar.theme_barStyle = [.default, .black, .black]
        navigationBar.theme_tintColor = Color.mainTint
        navigationBar.theme_titleTextAttributes = ThemeStringAttributesPicker.pickerWithAttributes(titleAttributes)

        // Theme Tab Bar
        let tabBar = UITabBar.appearance()
        tabBar.theme_barStyle = [.default, .black, .black]

        // Theme UISwitch
        UISwitch.appearance().theme_onTintColor = Color.mainTint

        // Show network activity indicator
        NetworkActivityIndicatorManager.shared.startDelay = 0.3
        NetworkActivityIndicatorManager.shared.isEnabled = true

        application.shortcutItems = Global.ShortcutItem.createItems(for: [.search, .wishes, .updates, .news])

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }

        let configuration = TelemetryManagerConfiguration(appID: Global.telemetryAppId)
        TelemetryManager.initialize(with: configuration)
        TelemetryManager.send(Global.Telemetry.launched.rawValue, with: [
            "isLinked": Preferences.deviceIsLinked.description,
            "isPlus": Preferences.isPlus.description
        ])

        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let item = Global.ShortcutItem(rawValue: shortcutItem.type) {
            delay(0.7) { application.open(item.resolvedUrl) }
        }
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // Handle IPA
        if url.isFileURL && IPAFileManager.shared.supportedFileExtensions.contains(url.pathExtension.lowercased()) {

            func copyIfNeeded() {
                if !url.absoluteString.contains("/Documents/Inbox/") {
                    IPAFileManager.shared.copyToDocuments(url: url)
                }
            }

            if !FileManager.default.isReadableFile(atPath: url.path) {
                // Handle 'Open in appdb' from share sheet
                if url.startAccessingSecurityScopedResource() {
                    copyIfNeeded()
                    url.stopAccessingSecurityScopedResource()
                }
            } else {
                copyIfNeeded()
            }

            guard let tabController = window?.rootViewController as? TabBarController else { return false }
            tabController.selectedIndex = 2
            guard let nav = tabController.viewControllers?[2] as? UINavigationController else { return false }
            guard let downloads = nav.viewControllers[0] as? Downloads else { return false }
            downloads.switchToIndex(i: 1)
            return true
        }

        // URL Schemes
        if let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            return decodeUrlScheme(from: queryItems)
        }

        return false
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        application(app, open: url, sourceApplication: "", annotation: options)
    }

    // MARK: - URL Schemes

    private func decodeUrlScheme(from queryItems: [URLQueryItem]) -> Bool {
        guard let tab = window?.rootViewController as? TabBarController else { return false }

        // Tab selection, e.g. appdb-ios://?tab=search

        if let index = queryItems.firstIndex(where: { $0.name == "tab" }) {
            guard let value = queryItems[index].value else { return false }

            dismissCurrentNavIfAny()

            switch value {
            case "featured":
                tab.selectedIndex = 0
            case "search":
                tab.selectedIndex = 1
            case "downloads":
                tab.selectedIndex = 2
            case "settings":
                tab.selectedIndex = 3
            case "updates":
                tab.selectedIndex = 4
            case "news":
                tab.selectedIndex = 3
                guard let nav = tab.viewControllers?[3] as? UINavigationController else { break }
                guard let settings = nav.viewControllers[0] as? Settings else { break }
                settings.push(News())
            case "system_status":
                tab.selectedIndex = 3
                guard let nav = tab.viewControllers?[3] as? UINavigationController else { break }
                guard let settings = nav.viewControllers[0] as? Settings else { break }
                settings.push(SystemStatus())
            case "device_status":
                tab.selectedIndex = 3
                guard let nav = tab.viewControllers?[3] as? UINavigationController else { break }
                guard let settings = nav.viewControllers[0] as? Settings else { break }
                settings.push(DeviceStatus())
            case "wishes":
                tab.selectedIndex = 0
                guard let nav = tab.viewControllers?[0] as? UINavigationController else { break }
                if Global.isIpad {
                    let modalNav = DismissableModalNavController(rootViewController: Wishes())
                    modalNav.modalPresentationStyle = .formSheet
                    nav.present(modalNav, animated: true)
                } else {
                    nav.present(UINavigationController(rootViewController: Wishes()), animated: true)
                }
            case "custom_apps":
                tab.selectedIndex = 0
                guard let nav = tab.viewControllers?[0] as? UINavigationController else { break }
                let customAppsViewController = SeeAll(title: "Custom Apps".localized(),
                                                  type: .cydia, category: "0", price: .all, order: .added)
                if Global.isIpad {
                    let modalNav = DismissableModalNavController(rootViewController: customAppsViewController)
                    nav.modalPresentationStyle = .formSheet
                    nav.present(modalNav, animated: true)
                } else {
                    nav.pushViewController(customAppsViewController, animated: true)
                }
            default: break
            }

            return true
        }

        // Open details page, e.g. appdb-ios://?trackid=x&type=ios

        if let index1 = queryItems.firstIndex(where: { $0.name == "trackid" }), let index2 = queryItems.firstIndex(where: { $0.name == "type" }) {
            guard let trackid = queryItems[index1].value, let typeString = queryItems[index2].value else { return false }
            guard let nav = tab.viewControllers?[0] as? UINavigationController else { return false }
            guard let type = ItemType(rawValue: typeString) else { return false }

            tab.selectedIndex = 0

            let vc = Details(type: type, trackid: trackid)

            if Global.isIpad {
                if let presented = nav.topViewController?.presentedViewController as? DismissableModalNavController {
                    // Already showing an app, add to stack
                    if presented.topViewController is Details {
                        presented.pushViewController(vc, animated: true)
                    } else {
                        dismissCurrentNavIfAny()
                        let navController = DismissableModalNavController(rootViewController: vc)
                        navController.modalPresentationStyle = .formSheet
                        nav.present(navController, animated: true)
                    }
                } else {
                    let navController = DismissableModalNavController(rootViewController: vc)
                    navController.modalPresentationStyle = .formSheet
                    nav.present(navController, animated: true)
                }
            } else {
                nav.pushViewController(vc, animated: true)
            }

            return true
        }

        // Search query with type, e.g. appdb-ios://?q=Facebook&type=ios

        if let index1 = queryItems.firstIndex(where: { $0.name == "q" }), let index2 = queryItems.firstIndex(where: { $0.name == "type" }) {
            guard let query = queryItems[index1].value, let typeString = queryItems[index2].value else { return false }
            guard let type = ItemType(rawValue: typeString) else { return false }

            dismissCurrentNavIfAny()

            tab.selectedIndex = 1

            guard let nav = tab.viewControllers?[1] as? UINavigationController else { return false }
            guard let search = nav.viewControllers[0] as? Search else { return false }

            delay(0.7) {
                search.setItemTypeAndSearch(type: type, query: query)
            }

            return true
        }

        // Open news with id, e.g. appdb-ios://?news_id=x

        if let index1 = queryItems.firstIndex(where: { $0.name == "news_id" }) {
            guard let id = queryItems[index1].value else { return false }

            dismissCurrentNavIfAny()

            tab.selectedIndex = 3
            guard let nav = tab.viewControllers?[3] as? UINavigationController else { return false }
            guard let settings = nav.viewControllers[0] as? Settings else { return false }
            settings.push(News())

            let newsDetailViewController = NewsDetail(with: id)

            if Global.isIpad {
                delay(1) {
                    if let presented = nav.topViewController?.presentedViewController as? DismissableModalNavController {
                        presented.pushViewController(newsDetailViewController, animated: true)
                    }
                }
            } else {
                nav.pushViewController(newsDetailViewController, animated: true)
            }

            return true
        }

        // Open url in IPAWebViewController, e.g. appdb-ios://?icon=https://some.app/icon.png&url=https://appdb.to

        if let index1 = queryItems.firstIndex(where: { $0.name == "url" }) {
            guard let urlString = queryItems[index1].value, let url = URL(string: urlString) else { return false }

            dismissCurrentNavIfAny()

            guard let nav = tab.viewControllers?[2] as? UINavigationController else { return false }
            guard let downloads = nav.viewControllers[0] as? Downloads else { return false }

            let webVc: IPAWebViewController
            if let index2 = queryItems.firstIndex(where: { $0.name == "icon" }), let iconUrlString = queryItems[index2].value {
                webVc = IPAWebViewController(delegate: downloads, url: url, appIcon: iconUrlString)
            } else {
                webVc = IPAWebViewController(delegate: downloads, url: url)
            }
            let navController = IPAWebViewNavController(rootViewController: webVc)
            downloads.present(navController, animated: true)

            return true
        }

        // Authorize app with link code, e.g. appdb-ios://?action=authorize&code=x

        if let index1 = queryItems.firstIndex(where: { $0.name == "action" }), let index2 = queryItems.firstIndex(where: { $0.name == "code" }) {
            guard let action = queryItems[index1].value, let code = queryItems[index2].value else { return false }
            guard action == "authorize", !code.isEmpty, !Preferences.deviceIsLinked else { return false }

            dismissCurrentNavIfAny()

            tab.selectedIndex = 3

            guard let nav = tab.viewControllers?[3] as? UINavigationController else { return false }
            guard let settings = nav.viewControllers[0] as? Settings else { return false }

            delay(0.5) {
                settings.showlinkCodeFromURLSchemeBulletin(code: code)
            }

            return true
        }

        return false
    }

    private func dismissCurrentNavIfAny() {
        guard let tab = window?.rootViewController as? TabBarController else { return }

        if let currentNav = (tab.viewControllers?[tab.selectedIndex] as? UINavigationController)?.topViewController?.presentedViewController as? UINavigationController {
            currentNav.dismiss(animated: true)
        }

        if tab.selectedIndex == 3 {
            guard let nav = tab.viewControllers?[3] as? UINavigationController else { return }
            guard let settings = nav.viewControllers[0] as? Settings else { return }

            DispatchQueue.main.async {
                if settings.deviceLinkBulletinManager.isShowingBulletin {
                    settings.deviceLinkBulletinManager.dismissBulletin()
                } else if settings.deauthorizeBulletinManager.isShowingBulletin {
                    settings.deauthorizeBulletinManager.dismissBulletin()
                }
            }
        }
    }
}
