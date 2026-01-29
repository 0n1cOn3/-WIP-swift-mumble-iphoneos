import UIKit

class MUPreferencesViewController: UITableViewController {
    private weak var activeTextField: UITextField?

    init() {
        super.init(style: .grouped)
        self.preferredContentSize = CGSize(width: 320, height: 480)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        UserDefaults.standard.synchronize()
        if let delegate = UIApplication.shared.delegate as? MUApplicationDelegate {
            delegate.reloadPreferences()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController?.navigationBar.barStyle = .black
            navigationController?.navigationBar.setBackgroundImage(MUImage.clearColorImage(), for: .default)
            navigationController?.navigationBar.isTranslucent = true
        }

        tableView.backgroundView = MUBackgroundView.backgroundView()
        if #available(iOS 7.0, *) {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
        } else {
            tableView.separatorStyle = .none
        }

        title = NSLocalizedString("Preferences", comment: "Title for preferences screen")
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else if section == 1 {
            #if ENABLE_REMOTE_CONTROL
            return 3
            #else
            return 2
            #endif
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "PreferencesCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
            UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.selectionStyle = .default
        cell.accessoryType = .none

        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let volSlider = UISlider()
                volSlider.minimumTrackTintColor = .black
                volSlider.maximumValue = 1.0
                volSlider.minimumValue = 0.0
                volSlider.value = UserDefaults.standard.float(forKey: "AudioOutputVolume")
                cell.textLabel?.text = NSLocalizedString("Volume", comment: "Volume settings option")
                cell.accessoryView = volSlider
                cell.selectionStyle = .none
                volSlider.addTarget(self, action: #selector(audioVolumeChanged(_:)), for: .valueChanged)
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AudioTransmitCell") ??
                    UITableViewCell(style: .value1, reuseIdentifier: "AudioTransmitCell")
                cell.textLabel?.text = NSLocalizedString("Transmission", comment: "Transmission settings option")
                let xmit = UserDefaults.standard.string(forKey: "AudioTransmitMethod")
                if xmit == "vad" {
                    cell.detailTextLabel?.text = NSLocalizedString("Voice Activated", comment: "Voice activated transmission mode")
                } else if xmit == "ptt" {
                    cell.detailTextLabel?.text = NSLocalizedString("Push-to-talk", comment: "Push-to-talk transmission mode")
                } else if xmit == "continuous" {
                    cell.detailTextLabel?.text = NSLocalizedString("Continuous", comment: "Continuous transmission mode")
                }
                cell.detailTextLabel?.textColor = MUColor.selectedTextColor()
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell
            default:
                cell.textLabel?.text = NSLocalizedString("Advanced", comment: "Advanced settings option")
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let tcpSwitch = UISwitch()
                tcpSwitch.isOn = UserDefaults.standard.bool(forKey: "NetworkForceTCP")
                cell.textLabel?.text = NSLocalizedString("Force TCP", comment: "Force TCP connection option")
                cell.accessoryView = tcpSwitch
                cell.selectionStyle = .none
                tcpSwitch.onTintColor = .black
                tcpSwitch.addTarget(self, action: #selector(forceTCPChanged(_:)), for: .valueChanged)
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PrefCertificateCell") ??
                    UITableViewCell(style: .value1, reuseIdentifier: "PrefCertificateCell")
                let cert = MUCertificateController.defaultCertificate()
                cell.textLabel?.text = NSLocalizedString("Certificate", comment: "Certificate settings option")
                cell.detailTextLabel?.text = cert != nil ? cert?.subjectName() : NSLocalizedString("None", comment: "None (No certificate chosen)")
                cell.detailTextLabel?.textColor = MUColor.selectedTextColor()
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell
            #if ENABLE_REMOTE_CONTROL
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "RemoteControlCell") ??
                    UITableViewCell(style: .value1, reuseIdentifier: "RemoteControlCell")
                cell.textLabel?.text = NSLocalizedString("Remote Control", comment: "Remote control settings option")
                let isOn = MURemoteControlServer.sharedRemoteControlServer().isRunning
                cell.detailTextLabel?.text = isOn ? NSLocalizedString("On", comment: "Remote control is enabled") : NSLocalizedString("Off", comment: "Remote control is disabled")
                cell.detailTextLabel?.textColor = MUColor.selectedTextColor()
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell
            #endif
            default:
                break
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Audio", comment: "Audio section header"))
        } else if section == 1 {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Network", comment: "Network section header"))
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        MUTableViewHeaderLabel.defaultHeaderHeight()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                let audioXmit = MUAudioTransmissionPreferencesViewController()
                navigationController?.pushViewController(audioXmit, animated: true)
            } else if indexPath.row == 2 {
                let advAudio = MUAdvancedAudioPreferencesViewController()
                navigationController?.pushViewController(advAudio, animated: true)
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 1 {
                let certPref = MUCertificatePreferencesViewController()
                navigationController?.pushViewController(certPref, animated: true)
            }
            #if ENABLE_REMOTE_CONTROL
            if indexPath.row == 2 {
                let remote = MURemoteControlPreferencesViewController()
                navigationController?.pushViewController(remote, animated: true)
            }
            #endif
        }
    }

    @objc private func audioVolumeChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "AudioOutputVolume")
    }

    @objc private func forceTCPChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "NetworkForceTCP")
    }
}

