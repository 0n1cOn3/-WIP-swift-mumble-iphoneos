// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Audio quality preset picker allowing selection between
/// Low, Balanced, and High quality settings.
@objc(MUAudioQualityPreferencesViewController)
@objcMembers
class MUAudioQualityPreferencesViewController: UITableViewController {

    // MARK: - Initialization

    init() {
        super.init(style: .grouped)
        preferredContentSize = CGSize(width: 320, height: 480)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = NSLocalizedString("Audio Quality", comment: "")

        tableView.backgroundView = MUBackgroundView.backgroundView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.isScrollEnabled = false
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MUAudioQualityPreferencesCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        guard let cell = cell else { return UITableViewCell() }

        let defaults = UserDefaults.standard
        let qualityKind = defaults.string(forKey: "AudioQualityKind") ?? ""

        cell.selectionStyle = .default
        cell.accessoryView = nil
        cell.textLabel?.textColor = .black

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = NSLocalizedString("Low", comment: "")
            cell.detailTextLabel?.text = NSLocalizedString("16 kbit/s, 60 ms audio per packet", comment: "")
            if qualityKind == "low" {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedText()
            }
        case 1:
            cell.textLabel?.text = NSLocalizedString("Balanced", comment: "")
            cell.detailTextLabel?.text = NSLocalizedString("40 kbit/s, 20 ms audio per packet", comment: "")
            if qualityKind == "balanced" {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedText()
            }
        case 2:
            cell.textLabel?.text = NSLocalizedString("High", comment: "")
            cell.detailTextLabel?.text = NSLocalizedString("72 kbit/s, 10 ms audio per packet", comment: "")
            if qualityKind == "high" {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedText()
            }
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Quality Presets", comment: ""))
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return MUTableViewHeaderLabel.defaultHeaderHeight()
        }
        return 0
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Clear all checkmarks
        for i in 0..<3 {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
                cell.accessoryView = nil
                cell.textLabel?.textColor = .black
            }
        }

        // Set selected checkmark
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
            cell.textLabel?.textColor = MUColor.selectedText()
        }

        // Update preference
        let qualityValues = ["low", "balanced", "high"]
        if indexPath.row < qualityValues.count {
            MUAudioSessionManager.shared.updateCodecQualityPreset(qualityValues[indexPath.row])
        }
    }
}
