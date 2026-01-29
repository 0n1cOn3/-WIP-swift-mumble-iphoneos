// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Advanced audio preferences controller for configuring audio quality,
/// input processing, output settings, and codec options.
@objc(MUAdvancedAudioPreferencesViewController)
@objcMembers
class MUAdvancedAudioPreferencesViewController: UITableViewController {

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

        title = NSLocalizedString("Advanced Audio", comment: "")

        tableView.backgroundView = MUBackgroundView.backgroundView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.isScrollEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSubsystemRestarted(_:)),
            name: NSNotification.Name("MKAudioDidRestartNotification"),
            object: nil
        )

        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // Quality
        case 1: return 2  // Audio Input
        case 2: return 2  // Audio Output
        case 3: return 1  // Opus Codec
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MUAdvancedAudioPreferencesCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        }

        guard let cell = cell else { return UITableViewCell() }

        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        cell.accessoryType = .none

        let defaults = UserDefaults.standard

        switch indexPath.section {
        case 0:
            // Quality section
            cell.textLabel?.text = NSLocalizedString("Quality", comment: "")
            cell.detailTextLabel?.textColor = MUColor.selectedText()
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default

            let qualityKind = defaults.string(forKey: "AudioQualityKind") ?? ""
            switch qualityKind {
            case "low":
                cell.detailTextLabel?.text = NSLocalizedString("Low", comment: "")
            case "balanced":
                cell.detailTextLabel?.text = NSLocalizedString("Balanced", comment: "")
            case "high":
                cell.detailTextLabel?.text = NSLocalizedString("High", comment: "")
            default:
                cell.detailTextLabel?.text = NSLocalizedString("Custom", comment: "")
            }

        case 1:
            // Audio Input section
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Preprocessing", comment: "")
                cell.selectionStyle = .none

                let preprocSwitch = UISwitch()
                preprocSwitch.onTintColor = .black
                preprocSwitch.isOn = defaults.bool(forKey: "AudioPreprocessor")
                preprocSwitch.addTarget(self, action: #selector(preprocessingChanged(_:)), for: .valueChanged)
                cell.accessoryView = preprocSwitch
            } else if indexPath.row == 1 {
                if defaults.bool(forKey: "AudioPreprocessor") {
                    cell.textLabel?.text = NSLocalizedString("Echo Cancellation", comment: "")
                    cell.selectionStyle = .none

                    let echoCancelSwitch = UISwitch()
                    echoCancelSwitch.onTintColor = .black
                    echoCancelSwitch.isOn = defaults.bool(forKey: "AudioEchoCancel")
                    echoCancelSwitch.isEnabled = MKAudio.shared().echoCancellationAvailable()
                    if !echoCancelSwitch.isEnabled {
                        echoCancelSwitch.isOn = false
                    }
                    echoCancelSwitch.addTarget(self, action: #selector(echoCancelChanged(_:)), for: .valueChanged)
                    cell.accessoryView = echoCancelSwitch
                } else {
                    cell.textLabel?.text = NSLocalizedString("Mic Boost", comment: "")
                    cell.selectionStyle = .none

                    let slider = UISlider()
                    slider.maximumValue = 2.0
                    slider.minimumValue = 0.0
                    let boost = defaults.float(forKey: "AudioMicBoost")
                    slider.minimumTrackTintColor = boost > 1.0 ? MUColor.badPing() : MUColor.goodPing()
                    slider.value = boost
                    slider.addTarget(self, action: #selector(micBoostChanged(_:)), for: .valueChanged)
                    cell.accessoryView = slider
                }
            }

        case 2:
            // Audio Output section
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Sidetone", comment: "")
                cell.detailTextLabel?.textColor = MUColor.selectedText()
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default

                if defaults.bool(forKey: "AudioSidetone") {
                    cell.detailTextLabel?.text = NSLocalizedString("On", comment: "")
                } else {
                    cell.detailTextLabel?.text = NSLocalizedString("Off", comment: "")
                }
            } else if indexPath.row == 1 {
                cell.textLabel?.text = NSLocalizedString("Speakerphone Mode", comment: "")
                cell.selectionStyle = .none

                let speakerPhoneSwitch = UISwitch()
                speakerPhoneSwitch.onTintColor = .black
                speakerPhoneSwitch.isOn = defaults.bool(forKey: "AudioSpeakerPhoneMode")
                speakerPhoneSwitch.addTarget(self, action: #selector(speakerPhoneModeChanged(_:)), for: .valueChanged)
                cell.accessoryView = speakerPhoneSwitch
            }

        case 3:
            // Opus Codec section
            cell.textLabel?.text = NSLocalizedString("Force CELT Mode", comment: "")
            cell.selectionStyle = .none

            let celtSwitch = UISwitch()
            celtSwitch.onTintColor = .black
            celtSwitch.isOn = defaults.bool(forKey: "AudioOpusCodecForceCELTMode")
            celtSwitch.addTarget(self, action: #selector(opusCodecForceCELTModeChanged(_:)), for: .valueChanged)
            cell.accessoryView = celtSwitch

        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Transmission Quality", comment: ""))
        case 1:
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Audio Input", comment: ""))
        case 2:
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Audio Output", comment: ""))
        case 3:
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Opus Codec", comment: ""))
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= 0 && section <= 3 {
            return MUTableViewHeaderLabel.defaultHeaderHeight()
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: "AudioPreprocessor") {
                if !MKAudio.shared().echoCancellationAvailable() {
                    let text = NSLocalizedString("Echo Cancellation is not available when using the current audio peripheral.", comment: "")
                    let label = MUTableViewHeaderLabel.label(withText: text)
                    label.font = UIFont.systemFont(ofSize: 16.0)
                    label.lineBreakMode = .byWordWrapping
                    label.numberOfLines = 0
                    return label
                }
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: "AudioPreprocessor") {
                if !MKAudio.shared().echoCancellationAvailable() {
                    return 44.0
                }
            }
        }
        return 0
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            let audioQual = MUAudioQualityPreferencesViewController()
            navigationController?.pushViewController(audioQual, animated: true)
        } else if indexPath.section == 2 && indexPath.row == 0 {
            let sidetonePrefs = MUAudioSidetonePreferencesViewController()
            navigationController?.pushViewController(sidetonePrefs, animated: true)
        }
    }

    // MARK: - Actions

    @objc private func preprocessingChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AudioPreprocessor")
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }

    @objc private func echoCancelChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AudioEchoCancel")
    }

    @objc private func micBoostChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "AudioMicBoost")
        sender.minimumTrackTintColor = sender.value > 1.0 ? MUColor.badPing() : MUColor.goodPing()
    }

    @objc private func speakerPhoneModeChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AudioSpeakerPhoneMode")
    }

    @objc private func opusCodecForceCELTModeChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AudioOpusCodecForceCELTMode")
    }

    @objc private func audioSubsystemRestarted(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "AudioPreprocessor") {
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
        }
    }
}
