import UIKit

final class MUAudioTransmissionPreferencesViewController: UITableViewController {
    private enum TransmissionMethod: String {
        case vad = "vad"
        case pushToTalk = "ptt"
        case continuous = "continuous"

        static func current() -> TransmissionMethod {
            let stored = UserDefaults.standard.string(forKey: "AudioTransmitMethod") ?? TransmissionMethod.vad.rawValue
            return TransmissionMethod(rawValue: stored) ?? .vad
        }

        func store() {
            UserDefaults.standard.set(rawValue, forKey: "AudioTransmitMethod")
            _ = MUAudioSessionManager.shared.updateTransmitMethod(withString: rawValue)
        }
    }

    // MARK: - Lifecycle
    init() {
        super.init(style: .grouped)
        preferredContentSize = CGSize(width: 320, height: 480)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = NSLocalizedString("Transmission", comment: "Audio transmission preferences title")
        tableView.backgroundView = MUBackgroundView.backgroundView()

        tableView.separatorStyle = .none
        tableView.separatorInset = .zero

        tableView.isScrollEnabled = false
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let current = TransmissionMethod.current()
        switch section {
        case 0:
            return 3
        case 1:
            return (current == .pushToTalk || current == .vad) ? 1 : 0
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = TransmissionMethod.current()
        if indexPath.section == 1 && indexPath.row == 0 && current == .pushToTalk {
            let identifier = "AudioXmitPTTCell"
            let pttCell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
            let mouthView = UIImageView(image: UIImage(named: "talkbutton_off"))
            mouthView.contentMode = .center
            mouthView.isOpaque = false
            pttCell.backgroundView = mouthView
            pttCell.selectionStyle = .none
            pttCell.textLabel?.text = nil
            pttCell.accessoryView = nil
            pttCell.accessoryType = .none
            pttCell.backgroundColor = .clear
            return pttCell
        }

        let identifier = "AudioXmitOptionCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.textLabel?.textColor = .black
        cell.selectionStyle = .default

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = NSLocalizedString("Voice Activated", comment: "Voice activation option")
            if current == .vad {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedTextColor()
            }
        case (0, 1):
            cell.textLabel?.text = NSLocalizedString("Push-to-talk", comment: "Push to talk option")
            if current == .pushToTalk {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedTextColor()
            }
        case (0, 2):
            cell.textLabel?.text = NSLocalizedString("Continuous", comment: "Continuous transmission option")
            if current == .continuous {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedTextColor()
            }
        case (1, 0):
            if current == .vad {
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = NSLocalizedString("Voice Activity Configuration", comment: "Voice activity configuration")
                cell.selectionStyle = .default
            }
        default:
            break
        }

        return cell
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let current = TransmissionMethod.current()
        if section == 0 {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Transmission Method", comment: "Transmission method header"))
        }

        let parent = UIView(frame: .zero)
        let label = MUTableViewHeaderLabel.label(withText: nil)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.contentMode = .top

        switch current {
        case .vad:
            label.text = NSLocalizedString("In Voice Activity mode, Mumble transmits\nyour voice when it senses you talking.\nFine-tune it below:\n", comment: "Voice activity description")
            label.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 70)
            parent.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 80)
        case .pushToTalk:
            label.text = NSLocalizedString("In Push-to-Talk mode, touch the mouth\nicon to speak to other people when\nconnected to a server.\n", comment: "Push to talk description")
            label.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 70)
            parent.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 70)
        case .continuous:
            label.text = NSLocalizedString("In Continuous mode, Mumble will\ncontinuously transmit all recorded audio.\n", comment: "Continuous description")
            label.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 50)
            parent.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 50)
        }

        parent.addSubview(label)
        return parent
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            switch TransmissionMethod.current() {
            case .vad:
                return 80
            case .pushToTalk:
                return 70
            case .continuous:
                return 50
            }
        }

        return MUTableViewHeaderLabel.defaultHeaderHeight()
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 1, let label = view as? MUTableViewHeaderLabel {
            label.sizeToFit()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 && TransmissionMethod.current() == .pushToTalk {
            return 100
        }
        return 44
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = TransmissionMethod.current()

        if indexPath.section == 0 {
            for row in 0..<3 {
                let rowIndexPath = IndexPath(row: row, section: 0)
                if let cell = tableView.cellForRow(at: rowIndexPath) {
                    cell.accessoryView = nil
                    cell.textLabel?.textColor = .black
                }
            }

            tableView.deselectRow(at: indexPath, animated: true)

            switch indexPath.row {
            case 0:
                TransmissionMethod.vad.store()
            case 1:
                TransmissionMethod.pushToTalk.store()
            case 2:
                TransmissionMethod.continuous.store()
            default:
                break
            }

            tableView.reloadSections(IndexSet(integer: 1), with: .fade)

            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryView = UIImageView(image: UIImage(named: "GrayCheckmark"))
                cell.textLabel?.textColor = MUColor.selectedTextColor()
            }
        } else if indexPath.section == 1 && indexPath.row == 0 && current == .vad {
            tableView.deselectRow(at: indexPath, animated: true)
            let setup = MUVoiceActivitySetupViewController()
            navigationController?.pushViewController(setup, animated: true)
        }
    }
}
