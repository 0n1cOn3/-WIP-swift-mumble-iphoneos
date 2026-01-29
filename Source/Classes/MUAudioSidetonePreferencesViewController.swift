// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Sidetone preferences controller for enabling sidetone feedback
/// and adjusting playback volume.
@objc(MUAudioSidetonePreferencesViewController)
@objcMembers
class MUAudioSidetonePreferencesViewController: UITableViewController {

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

        title = NSLocalizedString("Sidetone", comment: "")

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
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MUAudioSidetonePreferencesCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        guard let cell = cell else { return UITableViewCell() }

        let defaults = UserDefaults.standard

        cell.selectionStyle = .none
        cell.accessoryView = nil

        if indexPath.row == 0 {
            cell.textLabel?.text = NSLocalizedString("Enable Sidetone", comment: "")

            let sidetoneSwitch = UISwitch()
            sidetoneSwitch.onTintColor = .black
            sidetoneSwitch.isOn = defaults.bool(forKey: "AudioSidetone")
            sidetoneSwitch.addTarget(self, action: #selector(sidetoneStatusChanged(_:)), for: .valueChanged)
            cell.accessoryView = sidetoneSwitch
        } else if indexPath.row == 1 {
            cell.textLabel?.text = NSLocalizedString("Playback Volume", comment: "")

            let sidetoneSlider = UISlider()
            sidetoneSlider.minimumValue = 0.0
            sidetoneSlider.maximumValue = 1.0
            sidetoneSlider.value = defaults.float(forKey: "AudioSidetoneVolume")
            sidetoneSlider.minimumTrackTintColor = .black
            sidetoneSlider.isEnabled = defaults.bool(forKey: "AudioSidetone")
            sidetoneSlider.addTarget(self, action: #selector(sidetoneVolumeChanged(_:)), for: .valueChanged)
            cell.accessoryView = sidetoneSlider
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Sidetone Feedback", comment: ""))
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return MUTableViewHeaderLabel.defaultHeaderHeight()
        }
        return 0
    }

    // MARK: - Actions

    @objc private func sidetoneStatusChanged(_ sidetoneSwitch: UISwitch) {
        UserDefaults.standard.set(sidetoneSwitch.isOn, forKey: "AudioSidetone")
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
    }

    @objc private func sidetoneVolumeChanged(_ sidetoneSlider: UISlider) {
        UserDefaults.standard.set(sidetoneSlider.value, forKey: "AudioSidetoneVolume")
    }
}
