import UIKit

private func showAlertDialog(title: String, msg: String) {
    DispatchQueue.main.async {
        let ok = NSLocalizedString("OK", comment: "OK button text for alert dialogs")
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ok, style: .cancel, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
}

class MUCertificateCreationView: UITableViewController {
    private var fullName: String?
    private var emailAddress: String?
    private var nameField: UITextField!
    private var emailField: UITextField!
    private var activeCell: UITableViewCell?
    private weak var activeTextField: UITextField?

    override init(style: UITableView.Style) {
        super.init(style: .grouped)
        self.preferredContentSize = CGSize(width: 320, height: 480)

        let name = NSLocalizedString("Name", comment: "Label for name field in certificate creation")
        let defaultName = NSLocalizedString("Mumble User", comment: "Default name placeholder for certificate creation")
        let email = NSLocalizedString("Email", comment: "Label for email field in certificate creation")
        let optional = NSLocalizedString("Optional", comment: "Placeholder text indicating email field is optional")
        let textFieldRect = CGRect(x: 110.0, y: 10.0, width: 185.0, height: 30.0)

        let nameCell = UITableViewCell(style: .value1, reuseIdentifier: "NameCell")
        nameCell.selectionStyle = .none
        nameCell.textLabel?.text = name
        nameField = UITextField(frame: textFieldRect)
        nameField.textColor = MUColor.selectedTextColor()
        nameField.addTarget(self, action: #selector(textFieldBeganEditing(_:)), for: .editingDidBegin)
        nameField.addTarget(self, action: #selector(textFieldEndedEditing(_:)), for: .editingDidEnd)
        nameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        nameField.addTarget(self, action: #selector(textFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)
        nameField.returnKeyType = .next
        nameField.textAlignment = .left
        nameField.placeholder = defaultName
        nameField.autocapitalizationType = .words
        nameField.text = fullName
        nameField.clearButtonMode = .whileEditing
        nameCell.contentView.addSubview(nameField)
        MUCertificateCreationView.configureCell(nameCell, with: nameField)

        let eCell = UITableViewCell(style: .value1, reuseIdentifier: "EmailCell")
        eCell.selectionStyle = .none
        eCell.textLabel?.text = email
        emailField = UITextField(frame: textFieldRect)
        emailField.textColor = MUColor.selectedTextColor()
        emailField.addTarget(self, action: #selector(textFieldBeganEditing(_:)), for: .editingDidBegin)
        emailField.addTarget(self, action: #selector(textFieldEndedEditing(_:)), for: .editingDidEnd)
        emailField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        emailField.addTarget(self, action: #selector(textFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)
        emailField.returnKeyType = .default
        emailField.textAlignment = .left
        emailField.placeholder = optional
        emailField.autocapitalizationType = .words
        emailField.keyboardType = .emailAddress
        emailField.text = fullName
        emailField.clearButtonMode = .whileEditing
        eCell.contentView.addSubview(emailField)
        MUCertificateCreationView.configureCell(eCell, with: emailField)

        cells = [nameCell, eCell]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var cells: [UITableViewCell] = []

    private static func configureCell(_ cell: UITableViewCell, with textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: textField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1, constant: 8)
        let bottom = NSLayoutConstraint(item: textField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1, constant: -8)
        let left = NSLayoutConstraint(item: textField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1, constant: 110)
        let right = NSLayoutConstraint(item: textField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([top, bottom, left, right])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = NSLocalizedString("New Certificate", comment: "Title of MUCertificateCreationView")
        tableView.backgroundView = MUBackgroundView.backgroundView()
        if #available(iOS 7, *) {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
        } else {
            tableView.separatorStyle = .none
        }
        let cancel = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel button for certificate creation"), style: .plain, target: self, action: #selector(cancelClicked(_:)))
        navigationItem.leftBarButtonItem = cancel
        let create = UIBarButtonItem(title: NSLocalizedString("Create", comment: "Create button for certificate creation"), style: .done, target: self, action: #selector(createClicked(_:)))
        navigationItem.rightBarButtonItem = create
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return cells.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return cells[indexPath.row] }

    @objc private func textFieldBeganEditing(_ sender: UITextField) {
        activeTextField = sender
        if sender == nameField { activeCell = cells[0] } else { activeCell = cells[1] }
    }

    @objc private func textFieldEndedEditing(_ sender: UITextField) { activeTextField = nil }

    @objc private func textFieldDidChange(_ sender: UITextField) {
        if sender == nameField { fullName = sender.text } else if sender == emailField { emailAddress = sender.text }
    }

    @objc private func textFieldDidEndOnExit(_ sender: UITextField) {
        if sender == nameField {
            emailField.becomeFirstResponder()
            activeTextField = emailField
            activeCell = cells[1]
        } else if sender == emailField {
            emailField.resignFirstResponder()
            activeTextField = nil
            activeCell = nil
        }
        if let cell = activeCell, let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    @objc private func keyboardWasShown(_ notification: Notification) {
        guard let kbSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        UIView.animate(withDuration: 0.2) {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
        } completion: { finished in
            if finished, let cell = self.activeCell, let idx = self.tableView.indexPath(for: cell) {
                self.tableView.scrollToRow(at: idx, at: .bottom, animated: true)
            }
        }
    }

    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        UIView.animate(withDuration: 0.2) {
            self.tableView.contentInset = .zero
            self.tableView.scrollIndicatorInsets = .zero
        }
    }

    @objc private func cancelClicked(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc private func createClicked(_ sender: Any) {
        let name = (fullName?.isEmpty ?? true) ? "Mumble User" : fullName!
        let email = (emailAddress?.isEmpty ?? true) ? nil : emailAddress
        let progress = MUCertificateCreationProgressView.progressView(withName: name, email: email)
        navigationController?.pushViewController(progress, animated: true)
        DispatchQueue.global(qos: .default).async {
            let cert = MKCertificate.selfSignedCertificate(withName: name, email: email)
            let pkcs12 = cert?.exportPKCS12(withPassword: "")
            guard let data = pkcs12 else {
                showAlertDialog(title: NSLocalizedString("Unable to generate certificate", comment: "Error title when certificate generation fails"), msg: NSLocalizedString("Mumble was unable to generate a certificate for your identity.", comment: "Error message when certificate generation fails"))
                DispatchQueue.main.async { self.navigationController?.dismiss(animated: true, completion: nil) }
                return
            }
            let dict = [kSecImportExportPassphrase as String: ""]
            var items: CFArray?
            let err = SecPKCS12Import(data as CFData, dict as CFDictionary, &items)
            if err == errSecSuccess, let arr = items as? [[String: Any]], let first = arr.first, let identity = first[kSecImportItemIdentity as String] {
                let op: [String: Any] = [kSecValueRef as String: identity, kSecReturnPersistentRef as String: true]
                var ref: CFTypeRef?
                let addErr = SecItemAdd(op as CFDictionary, &ref)
                if addErr == errSecSuccess, let dataRef = ref as? Data {
                    if MUCertificateController.defaultCertificate() == nil {
                        MUCertificateController.setDefaultCertificate(byPersistentRef: dataRef)
                    }
                } else if addErr == errSecDuplicateItem || (addErr == errSecSuccess && ref == nil) {
                    showAlertDialog(title: NSLocalizedString("Unable to add identity", comment: "Error title when identity cannot be added"), msg: NSLocalizedString("A certificate with the same name already exist.", comment: "Error message when certificate with same name exists"))
                }
            } else {
                showAlertDialog(title: NSLocalizedString("Import Error", comment: "Error title for certificate import failure"), msg: NSLocalizedString("Mumble was unable to import the generated certificate.", comment: "Error message when generated certificate cannot be imported"))
            }
            DispatchQueue.main.async {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

