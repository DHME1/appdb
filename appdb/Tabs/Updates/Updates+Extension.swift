//
//  Updates+Extension.swift
//  appdb
//
//  Created by ned on 11/11/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

extension Updates {

    var badgeCount: Int? {
        let count = updateableApps.count + nonUpdateableApps.count
        return count > 0 ? count : nil
    }

    convenience init() {
        if #available(iOS 13.0, *) {
            self.init(style: .insetGrouped)
        } else {
            self.init(style: .grouped)
        }
    }

    func setUp() {
        // Register for 3D Touch
        if #available(iOS 9.0, *), traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }

        tableView.tableFooterView = UIView()
        tableView.theme_backgroundColor = Color.tableViewBackgroundColor
        tableView.theme_separatorColor = Color.borderColor

        tableView.cellLayoutMarginsFollowReadableWidth = true

        tableView.register(UpdateCell.self, forCellReuseIdentifier: "cell")
        tableView.estimatedRowHeight = (135 ~~ 115)

        if #available(iOS 13.0, *) { } else {
            // Hide the 'Back' text on back button
            let backItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
            navigationItem.backBarButtonItem = backItem
        }

        // Add 'Ignored' button on the right
        let ignoredButton = UIBarButtonItem(title: "Ignored".localized(), style: .plain, target: self, action: #selector(self.openIgnored))
        navigationItem.rightBarButtonItem = ignoredButton
        navigationItem.rightBarButtonItem?.isEnabled = false

        state = .loading
        animated = true
        showsErrorButton = false

        // Observe deauthorization event
        NotificationCenter.default.addObserver(self, selector: #selector(onDeauthorization), name: .Deauthorized, object: nil)

        // Observe changes for 'showBadgeForUpdates' in preferences        
        observation = defaults.observe(.showBadgeForUpdates) { [weak self] _ in
            guard let self = self else { return }
            self.updateBadge()
        }
    }

    // Open Ignored view controller
    @objc func openIgnored() {
        let vc = Ignored()
        vc.delegate = self
        if Global.isIpad {
            let nav = DismissableModalNavController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            self.navigationController?.present(nav, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // Show help alert view controller when user clicks on ? button
    @objc func showHelp() {
        let message = "Apps installed from an external source, like the App Store or OTA distribution, can not be updated via appdb because of security limitations. We respect this!\n\nTo update these apps, please remove and reinstall them from appdb.\n\nTo hide these updates, swipe left on any of them and select 'Ignore'.".localized()
        let alertController = UIAlertController(title: "Non Updateable Apps".localized(), message: message, preferredStyle: .alert, adaptive: true)
        let okAction = UIAlertAction(title: "OK".localized(), style: .cancel)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    // Update badge only if user has 'showBadgeForUpdates' enabled
    func updateBadge() {
        updateBadge(with: Preferences.showBadgeForUpdates ? badgeCount : nil, for: .updates)
    }

    @objc func onDeauthorization() {
        self.cleanup()
        showErrorMessage(text: "An error has occurred".localized(), secondaryText: "Please authorize app from Settings first".localized(), animated: false)
    }
}

////////////////////////////////
//  PROTOCOL IMPLEMENTATIONS  //
////////////////////////////////

//
// MARK: - ElasticLabelDelegate
// Expand cell when 'more' button is pressed
//
extension Updates: ElasticLabelDelegate {
    func expand(_ label: ElasticLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            changelogCollapsedForIndexPath[indexPath] = false
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - React to changes in ignored list

extension Updates: IgnoredAppsListChanged {
    func ignoredChanged() {
        let updatedList = allApps.filter({ !$0.isIgnored }).sorted { $0.name.lowercased() < $1.name.lowercased() }
        let updatedList1 = updatedList.filter({ $0.updateable == 1 })
        let updatedList2 = updatedList.filter({ $0.updateable == 0 })

        if self.updateableApps != updatedList1 {
            self.updateableApps = updatedList1
        }

        if self.nonUpdateableApps != updatedList2 {
            self.nonUpdateableApps = updatedList2
        }

        if state != .error || errorMessage.text == "No updates found".localized() {
            self.state = .done
            self.updateBadge()
        }
    }
}

// MARK: - iOS 13 Context Menus

@available(iOS 13.0, *)
extension Updates {

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let apps = indexPath.section == 0 ? updateableApps : nonUpdateableApps
        guard apps.indices.contains(indexPath.row) else { return nil }
        let item = apps[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { Details(type: item.itemType, trackid: item.trackid.description) })
    }

    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            if let viewController = animator.previewViewController {
                if Global.isIpad {
                    let nav = DismissableModalNavController(rootViewController: viewController)
                    nav.modalPresentationStyle = .formSheet
                    self.navigationController?.present(nav, animated: true)
                } else {
                    self.show(viewController, sender: self)
                }
            }
        }
    }
}

// MARK: - 3D Touch Peek and Pop on updates

extension Updates: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        let apps = indexPath.section == 0 ? updateableApps : nonUpdateableApps
        guard apps.indices.contains(indexPath.row) else { return nil }
        let item = apps[indexPath.row]
        let vc = Details(type: item.itemType, trackid: item.trackid.description)
        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
