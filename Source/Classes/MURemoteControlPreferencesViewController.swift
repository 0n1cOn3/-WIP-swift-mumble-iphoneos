import UIKit

final class MURemoteControlPreferencesViewController: UITableViewController {
    // MARK: - Lifecycle
    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Remote Control", comment: "Remote control preferences title")
        tableView.backgroundView = MUBackgroundView.backgroundView()

        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero

        tableView.isScrollEnabled = false
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "RemoteControlPrefsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: identifier)

        if indexPath.section == 0 && indexPath.row == 0 {
            cell.textLabel?.text = NSLocalizedString("Enable", comment: "Enable remote control switch")
            let enableSwitch = UISwitch(frame: .zero)
            enableSwitch.addTarget(self, action: #selector(enableSwitchChanged(_:)), for: .valueChanged)
            enableSwitch.isOn = MURemoteControlServer.sharedRemoteControlServer().isRunning()
            enableSwitch.onTintColor = .black
            cell.accessoryView = enableSwitch
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - Actions
    @objc private func enableSwitchChanged(_ sender: UISwitch) {
        let server = MURemoteControlServer.sharedRemoteControlServer()
        UserDefaults.standard.set(sender.isOn, forKey: "RemoteControlServerEnabled")
        if sender.isOn {
            let started = server.start()
            if !started {
                sender.isOn = false
            }
        } else {
            server.stop()
        }
    }
}
