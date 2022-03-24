//
//  Updates.swift
//  appdb
//
//  Created by ned on 13/03/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

class Updates: LoadingTableView {

    var allApps: [UpdateableApp] = []
    var updateableApps: [UpdateableApp] = []
    var nonUpdateableApps: [UpdateableApp] = []

    // Keep track of which changelogs are collapsed
    var changelogCollapsedForIndexPath: [IndexPath: Bool] = [:]

    var isLoading = false

    var retryCount: Int = 0
    var timeoutLimit: Int = 60 // will throw error after 1 min of NOT_READY responses

    // Observation token to observe changes in Settings tab, used to update badge
    var observation: DefaultsObservation?

    deinit {
        observation = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Updates".localized()

        setUp()

        // Refresh action
        tableView.spr_setIndicatorHeader { [weak self] in
            self?.changelogCollapsedForIndexPath = [:]
            self?.animated = false
            self?.checkUpdates()
        }

        checkUpdates()
    }

    private var onlyOnce = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // https://stackoverflow.com/a/47839657/6022481
        if #available(iOS 11.2, *) {
            navigationController?.navigationBar.tintAdjustmentMode = .normal
            navigationController?.navigationBar.tintAdjustmentMode = .automatic
        }

        // If device was just linked, start checking for updates as soon as view appears
        if Preferences.deviceIsLinked, state == .error, errorMessage.text != "No updates found".localized() {
            self.animated = onlyOnce
            if onlyOnce { onlyOnce = false }
            state = .loading
            checkUpdates()
        }
    }

    // get update ticket -> check updates -> update UI

    func checkUpdates() {
        isLoading = true
        if Preferences.deviceIsLinked {
            API.getUpdatesTicket(success: { [weak self] ticket in
                guard let self = self else { return }

                self.getUpdates(ticket, done: { [weak self] error in
                    guard let self = self else { return }

                    if let error = error {
                        self.cleanup()
                        self.showErrorMessage(text: "Cannot connect".localized(), secondaryText: error, animated: self.animated)
                    } else {
                        self.isLoading = false
                        self.tableView.spr_endRefreshing()
                        self.updateBadge()
                        self.navigationItem.rightBarButtonItem?.isEnabled = true

                        if self.updateableApps.isEmpty && self.nonUpdateableApps.isEmpty {
                            self.tableView.reloadData()
                            self.showErrorMessage(text: "No updates found".localized(), animated: self.animated)
                        } else {
                            self.state = .done
                        }
                    }
                })
            }, fail: { [weak self] error in
                guard let self = self else { return }

                self.cleanup()
                self.showErrorMessage(text: "Cannot connect".localized(), secondaryText: error, animated: false)
            })
        } else {
            self.cleanup()
            showErrorMessage(text: "An error has occurred".localized(), secondaryText: "Please authorize app from Settings first".localized(), animated: false)
        }
    }

    internal func cleanup() {
        isLoading = false
        tableView.spr_endRefreshing()
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        updateableApps = []
        nonUpdateableApps = []
        tableView.reloadData()
        updateBadge()
    }

    func getUpdates(_ ticket: String, done: @escaping (_ error: String?) -> Void) {
        API.getUpdates(ticket: ticket, success: { [weak self] apps in
            guard let self = self else { return }

            self.retryCount = 0
            self.allApps = apps
            let mixed = apps.filter({ !$0.isIgnored }).sorted { $0.name.lowercased() < $1.name.lowercased() }
            self.updateableApps = mixed.filter { $0.updateable }
            self.nonUpdateableApps = mixed.filter { !$0.updateable }
            done(nil)
        }, fail: { [weak self] error, errorCode in
            guard let self = self else { return }

            if errorCode == "ERROR_NOT_READY" && self.retryCount < self.timeoutLimit {
                delay(1) {
                    self.retryCount += 1
                    self.getUpdates(ticket, done: done)
                }
            } else {
                self.retryCount = 0
                done(error.prettified)
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? updateableApps.count : nonUpdateableApps.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? UpdateCell else { return UITableViewCell() }
        let apps = indexPath.section == 0 ? updateableApps : nonUpdateableApps
        let item = apps[indexPath.row]

        // If there are two apps with the same name, append section at the end to distinguish them
        var name = item.name
        if apps.filter({ $0.name == name }).count > 1 {
            let stringToBeAdded = item.type == "ios" ? (" (" + "iOS".localized() + ")") : (" (" + "Cydia".localized() + ")")
            name.append(contentsOf: stringToBeAdded)
        }

        cell.whatsnew.collapsed = changelogCollapsedForIndexPath[indexPath] ?? true
        cell.configure(with: name, versionOld: item.versionOld, versionNew: item.versionNew, changelog: item.whatsnew, image: item.image)
        cell.whatsnew.delegated = self

        return cell
    }

    // Push details controller
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let apps = indexPath.section == 0 ? updateableApps : nonUpdateableApps
        let item = apps[indexPath.row]
        let vc = Details(type: item.itemType, trackid: item.trackid)
        if Global.isIpad {
            let nav = DismissableModalNavController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            self.navigationController?.present(nav, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Section header view

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UpdatesSectionHeader(showsButton: section == 1)
        var text: String!
        if section == 0 {
            if updateableApps.isEmpty { return nil }
            let count = updateableApps.count
            text = (count == 1 ? "%@ Updateable app" : "%@ Updateable apps").localizedFormat(String(count))
        } else {
            view.helpButton.addTarget(self, action: #selector(self.showHelp), for: .touchUpInside)
            if nonUpdateableApps.isEmpty { return nil }
            let count = nonUpdateableApps.count
            text = (count == 1 ? "%@ Non updateable app" : "%@ Non updateable apps").localizedFormat(String(count))
        }
        view.configure(with: text)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return updateableApps.isEmpty ? 0 : (60 ~~ 50)
        } else {
            return nonUpdateableApps.isEmpty ? 0 : (40 ~~ 30)
        }
    }

    // MARK: - Swipe to ignore

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let apps = indexPath.section == 0 ? updateableApps : nonUpdateableApps
        return !apps.isEmpty && !isLoading
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let ignore = UITableViewRowAction(style: .normal, title: "Ignore".localized()) { _, _ in
            let app = (indexPath.section == 0 ? self.updateableApps : self.nonUpdateableApps)[indexPath.row]
            let ignoredApp = IgnoredApp(trackid: app.trackid, name: app.name, iconUrl: app.image, type: app.type)
            Preferences.append(.ignoredUpdateableApps, element: ignoredApp)

            if indexPath.section == 0 {
                self.updateableApps.remove(at: indexPath.row)
                if self.updateableApps.isEmpty {
                    tableView.reloadData()
                    if self.nonUpdateableApps.isEmpty {
                        self.showErrorMessage(text: "No updates found".localized(), animated: self.animated)
                    }
                } else {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            } else {
                self.nonUpdateableApps.remove(at: indexPath.row)
                if self.nonUpdateableApps.isEmpty {
                    tableView.reloadData()
                    if self.updateableApps.isEmpty {
                        self.showErrorMessage(text: "No updates found".localized(), animated: self.animated)
                    }
                } else {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }

            self.changelogCollapsedForIndexPath[indexPath] = nil

            if let header = tableView.headerView(forSection: indexPath.section) as? UpdatesSectionHeader {
                if indexPath.section == 0 {
                    let count = self.updateableApps.count
                    header.configure(with: (count == 1 ? "%@ Updateable app" : "%@ Updateable apps").localizedFormat(String(count)))
                } else {
                    let count = self.nonUpdateableApps.count
                    header.configure(with: (count == 1 ? "%@ Non updateable app" : "%@ Non updateable apps").localizedFormat(String(count)))
                }
            }

            self.updateBadge()
        }
        ignore.backgroundColor = .red
        return [ignore]
    }

    // Reload data on rotation to update ElasticLabel text
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (_: UIViewControllerTransitionCoordinatorContext!) -> Void in
            guard self.tableView != nil else { return }
            if self.updateableApps.count + self.nonUpdateableApps.count > 0 { self.tableView.reloadData() }
        }, completion: nil)
    }
}
