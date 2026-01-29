// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// View controller for editing favourite server details.
@objc(MUFavouriteServerEditViewController)
@objcMembers
class MUFavouriteServerEditViewController: UITableViewController {

    // MARK: - Private Properties

    private var editMode: Bool = false
    private var favourite: MUFavouriteServer

    private weak var targetObject: AnyObject?
    private var doneActionSelector: Selector?

    private var descriptionCell: UITableViewCell!
    private var descriptionField: UITextField!
    private var addressCell: UITableViewCell!
    private var addressField: UITextField!
    private var portCell: UITableViewCell!
    private var portField: UITextField!
    private var usernameCell: UITableViewCell!
    private var usernameField: UITextField!
    private var passwordCell: UITableViewCell!
    private var passwordField: UITextField!

    private weak var activeTextField: UITextField?
    private weak var activeCell: UITableViewCell?

    // MARK: - Initialization

    @objc init(inEditMode editMode: Bool, withContentOfFavouriteServer favServ: MUFavouriteServer?) {
        self.editMode = editMode
        self.favourite = favServ?.copy() as? MUFavouriteServer ?? MUFavouriteServer()
        super.init(style: .grouped)
        setupCells()
    }

    @objc override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.favourite = MUFavouriteServer()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupCells()
    }

    required init?(coder: NSCoder) {
        self.favourite = MUFavouriteServer()
        super.init(coder: coder)
        setupCells()
    }

    private func setupCells() {
        // Description cell
        descriptionCell = UITableViewCell(style: .value1, reuseIdentifier: "MUFavouriteServerDescription")
        descriptionCell.selectionStyle = .none
        descriptionCell.textLabel?.text = NSLocalizedString("Description", comment: "")
        descriptionField = createTextField()
        descriptionField.returnKeyType = .next
        descriptionField.placeholder = NSLocalizedString("Mumble Server", comment: "")
        descriptionField.autocapitalizationType = .words
        descriptionField.text = favourite.displayName
        descriptionCell.contentView.addSubview(descriptionField)
        Self.configureConstraints(cell: descriptionCell, textField: descriptionField)

        // Address cell
        addressCell = UITableViewCell(style: .value1, reuseIdentifier: "MUFavouriteServerAddress")
        addressCell.selectionStyle = .none
        addressCell.textLabel?.text = NSLocalizedString("Address", comment: "")
        addressField = createTextField()
        addressField.returnKeyType = .next
        addressField.placeholder = NSLocalizedString("Hostname or IP address", comment: "")
        addressField.autocapitalizationType = .none
        addressField.autocorrectionType = .no
        addressField.keyboardType = .URL
        addressField.text = favourite.hostName
        addressCell.contentView.addSubview(addressField)
        Self.configureConstraints(cell: addressCell, textField: addressField)

        // Port cell
        portCell = UITableViewCell(style: .value1, reuseIdentifier: "MUFavouriteServerPort")
        portCell.selectionStyle = .none
        portCell.textLabel?.text = NSLocalizedString("Port", comment: "")
        portField = createTextField()
        portField.returnKeyType = .next
        portField.adjustsFontSizeToFitWidth = true
        portField.placeholder = "64738"
        portField.autocapitalizationType = .none
        portField.autocorrectionType = .no
        portField.keyboardType = .numbersAndPunctuation
        portField.text = favourite.port != 0 ? "\(favourite.port)" : ""
        portCell.contentView.addSubview(portField)
        Self.configureConstraints(cell: portCell, textField: portField)

        // Username cell
        usernameCell = UITableViewCell(style: .value1, reuseIdentifier: "MUFavouriteServerUsername")
        usernameCell.selectionStyle = .none
        usernameCell.textLabel?.text = NSLocalizedString("Username", comment: "")
        usernameField = createTextField()
        usernameField.returnKeyType = .next
        usernameField.placeholder = UserDefaults.standard.string(forKey: "DefaultUserName")
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.isSecureTextEntry = false
        usernameField.text = favourite.userName
        usernameCell.contentView.addSubview(usernameField)
        Self.configureConstraints(cell: usernameCell, textField: usernameField)

        // Password cell
        passwordCell = UITableViewCell(style: .value1, reuseIdentifier: "MUFavouriteServerPassword")
        passwordCell.selectionStyle = .none
        passwordCell.textLabel?.text = NSLocalizedString("Password", comment: "")
        passwordField = createTextField()
        passwordField.returnKeyType = .default
        passwordField.placeholder = NSLocalizedString("Optional", comment: "")
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.isSecureTextEntry = true
        passwordField.text = favourite.password
        passwordCell.contentView.addSubview(passwordField)
        Self.configureConstraints(cell: passwordCell, textField: passwordField)
    }

    private func createTextField() -> UITextField {
        let textField = UITextField(frame: CGRect(x: 110, y: 10, width: 185, height: 30))
        textField.textColor = MUColor.selectedTextColor()
        textField.addTarget(self, action: #selector(textFieldBeganEditing(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldEndedEditing(_:)), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)
        textField.adjustsFontSizeToFitWidth = false
        textField.textAlignment = .left
        textField.clearButtonMode = .whileEditing
        return textField
    }

    private static func configureConstraints(cell: UITableViewCell, textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 110),
            textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.backgroundView = MUBackgroundView.backgroundView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWasShown(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillBeHidden(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        navigationItem.title = editMode
            ? NSLocalizedString("Edit Favourite", comment: "")
            : NSLocalizedString("New Favourite", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .plain,
            target: self,
            action: #selector(cancelClicked(_:))
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: ""),
            style: .done,
            target: self,
            action: #selector(doneClicked(_:))
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 5 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else { return UITableViewCell() }

        switch indexPath.row {
        case 0: return descriptionCell
        case 1: return addressCell
        case 2: return portCell
        case 3: return usernameCell
        case 4: return passwordCell
        default: return UITableViewCell()
        }
    }

    // MARK: - Actions

    @objc private func cancelClicked(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc private func doneClicked(_ sender: Any) {
        // Apply defaults for empty fields
        if favourite.displayName == nil || favourite.displayName?.isEmpty == true {
            favourite.displayName = NSLocalizedString("Mumble Server", comment: "")
        }
        if favourite.port == 0 {
            favourite.port = 64738
        }

        navigationController?.dismiss(animated: true, completion: nil)

        if let target = targetObject, let action = doneActionSelector {
            _ = target.perform(action, with: self)
        }
    }

    // MARK: - Data Accessors

    @objc func copyFavouriteFromContent() -> MUFavouriteServer {
        return (favourite.copy() as? MUFavouriteServer) ?? MUFavouriteServer()
    }

    // MARK: - Target/Action

    @objc func setTarget(_ target: Any?) {
        targetObject = target as AnyObject?
    }

    @objc func target() -> Any? {
        return targetObject
    }

    @objc func setDoneAction(_ action: Selector) {
        doneActionSelector = action
    }

    @objc func doneAction() -> Selector? {
        return doneActionSelector
    }

    // MARK: - Text Field Actions

    @objc private func textFieldBeganEditing(_ sender: UITextField) {
        activeTextField = sender

        switch sender {
        case descriptionField: activeCell = descriptionCell
        case addressField: activeCell = addressCell
        case portField: activeCell = portCell
        case usernameField: activeCell = usernameCell
        case passwordField: activeCell = passwordCell
        default: break
        }
    }

    @objc private func textFieldEndedEditing(_ sender: UITextField) {
        activeTextField = nil
    }

    @objc private func textFieldDidChange(_ sender: UITextField) {
        switch sender {
        case descriptionField:
            favourite.displayName = sender.text
        case addressField:
            favourite.hostName = sender.text
        case portField:
            favourite.port = UInt(sender.text ?? "") ?? 0
        case usernameField:
            favourite.userName = sender.text
        case passwordField:
            favourite.password = sender.text
        default:
            break
        }
    }

    @objc private func textFieldDidEndOnExit(_ sender: UITextField) {
        switch sender {
        case descriptionField:
            addressField.becomeFirstResponder()
            activeTextField = addressField
            activeCell = addressCell
        case addressField:
            portField.becomeFirstResponder()
            activeTextField = portField
            activeCell = portCell
        case portField:
            usernameField.becomeFirstResponder()
            activeTextField = usernameField
            activeCell = usernameCell
        case usernameField:
            passwordField.becomeFirstResponder()
            activeTextField = passwordField
            activeCell = passwordCell
        case passwordField:
            passwordField.resignFirstResponder()
            activeTextField = nil
            activeCell = nil
        default:
            break
        }

        if let cell = activeCell, let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    // MARK: - Keyboard Handling

    @objc private func keyboardWasShown(_ notification: Notification) {
        guard let info = notification.userInfo,
              let kbValue = info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }

        let kbSize = kbValue.cgRectValue.size

        UIView.animate(withDuration: 0.2) {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
        } completion: { finished in
            guard finished, let cell = self.activeCell, let indexPath = self.tableView.indexPath(for: cell) else { return }
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        UIView.animate(withDuration: 0.2) {
            self.tableView.contentInset = .zero
            self.tableView.scrollIndicatorInsets = .zero
        }
    }
}
