// Copyright 2013 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
import MumbleKit

/// Debug view controller for inspecting audio mixer state.
/// Shows active sources, removed sources, and updates in real-time.
@objc(MUAudioMixerDebugViewController)
@objcMembers
class MUAudioMixerDebugViewController: UITableViewController {

    // MARK: - Private Properties

    private var mixerInfo: [String: Any] = [:]
    private var timer: Timer?

    // MARK: - Initialization

    init() {
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "Mixer Debug"

        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneDebugging(_:))
        )
        navigationItem.rightBarButtonItem = doneButton

        timer = Timer.scheduledTimer(
            timeInterval: 0.001,
            target: self,
            selector: #selector(updateMixerInfo(_:)),
            userInfo: nil,
            repeats: true
        )
        updateMixerInfo(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Methods

    @objc private func updateMixerInfo(_ sender: Any) {
        if let info = MKAudio.shared().copyAudioOutputMixerDebugInfo() as? [String: Any] {
            mixerInfo = info
        }
        tableView.reloadData()
    }

    @objc private func doneDebugging(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Metadata
            return 1
        case 1: // Sources
            return (mixerInfo["sources"] as? [[String: Any]])?.count ?? 0
        case 2: // Removed
            return (mixerInfo["removed"] as? [[String: Any]])?.count ?? 0
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AudioMixerDebugCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        }

        guard let cell = cell else { return UITableViewCell() }

        cell.selectionStyle = .none

        switch indexPath.section {
        case 0: // Metadata
            if indexPath.row == 0 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm:ss:SSS"

                cell.textLabel?.text = "Last Updated"
                if let date = mixerInfo["last-update"] as? Date {
                    cell.detailTextLabel?.text = dateFormatter.string(from: date)
                } else {
                    cell.detailTextLabel?.text = "N/A"
                }
            }

        case 1: // Sources
            if let sources = mixerInfo["sources"] as? [[String: Any]],
               indexPath.row < sources.count {
                let info = sources[indexPath.row]
                cell.textLabel?.text = info["kind"] as? String ?? ""
                cell.detailTextLabel?.text = info["identifier"] as? String ?? ""
            }

        case 2: // Removed
            if let removed = mixerInfo["removed"] as? [[String: Any]],
               indexPath.row < removed.count {
                let info = removed[indexPath.row]
                cell.textLabel?.text = info["kind"] as? String ?? ""
                cell.detailTextLabel?.text = info["identifier"] as? String ?? ""
            }

        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Metadata"
        case 1: return "Sources"
        case 2: return "Removed"
        default: return "Unknown"
        }
    }
}
