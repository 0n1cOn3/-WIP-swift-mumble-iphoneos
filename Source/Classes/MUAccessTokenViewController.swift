import UIKit
import MumbleKit

@objc(MUAccessTokenViewController)
class MUAccessTokenViewController: UITableViewController {
    private let model: MKServerModel
    private var tokens: [String] = []
    private var tokenValue: String = ""
    private var editingRow: Int = -1
    private var editingCell: UITableViewCell?
    private var isFinalizingEdit = false

    @objc(initWithServerModel:)
    init(serverModel: MKServerModel) {
        self.model = serverModel
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = NSLocalizedString("Access Tokens", comment: "")

        if #available(iOS 7.0, *) {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonClicked)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonClicked)
        )

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

        if let dbTokens = MUDatabase.accessTokens(forServerWithHostname: model.hostname(), port: model.port()) as? [String] {
            tokens = dbTokens
        } else {
            tokens = []
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)

        model.setAccessTokens(tokens)
        MUDatabase.storeAccessTokens(tokens, forServerWithHostname: model.hostname(), port: model.port())
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tokens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "AccessTokenCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
            UITableViewCell(style: .default, reuseIdentifier: identifier)

        if indexPath.row == editingRow, let editingCell {
            return editingCell
        }

        let token = tokens[indexPath.row]
        if token.isEmpty {
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = NSLocalizedString("(Empty)", comment: "")
        } else {
            cell.textLabel?.textColor = .black
            cell.textLabel?.text = token
        }
        cell.selectionStyle = .none

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        editingRow == -1
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            tokens.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if editingRow != -1 {
            return
        }
        editItem(at: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    // MARK: - Actions
    private func editItem(at row: Int) {
        editingRow = row
        tokenValue = tokens[row]

        let newEditingCell = UITableViewCell(style: .default, reuseIdentifier: "AccessTokenEditingCell")
        let editingField = UITextField()
        if #available(iOS 7.0, *) {
            editingField.font = .boldSystemFont(ofSize: 18.0)
        } else {
            editingField.font = .boldSystemFont(ofSize: 20.0)
        }
        editingField.autocorrectionType = .no
        editingField.addTarget(self, action: #selector(textFieldBeganEditing(_:)), for: .editingDidBegin)
        editingField.addTarget(self, action: #selector(textFieldEndedEditing(_:)), for: .editingDidEnd)
        editingField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        editingField.addTarget(self, action: #selector(textFieldDidEndOnExit(_:)), for: .editingDidEndOnExit)
        editingField.text = tokenValue
        editingField.returnKeyType = .done

        newEditingCell.contentView.addSubview(editingField)

        editingField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editingField.topAnchor.constraint(equalTo: newEditingCell.contentView.topAnchor, constant: 1),
            editingField.bottomAnchor.constraint(equalTo: newEditingCell.contentView.bottomAnchor),
            editingField.leadingAnchor.constraint(equalTo: newEditingCell.contentView.leadingAnchor, constant: 8),
            editingField.trailingAnchor.constraint(equalTo: newEditingCell.contentView.trailingAnchor)
        ])

        editingCell = newEditingCell
        editingField.becomeFirstResponder()
    }

    @objc private func addButtonClicked() {
        if editingRow != -1 {
            return
        }
        let insertRow = tokens.count
        tokens.append("")
        editItem(at: insertRow)
        tableView.insertRows(at: [IndexPath(row: insertRow, section: 0)], with: .bottom)
    }

    @objc private func doneButtonClicked() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Text field actions
    @objc private func textFieldBeganEditing(_ sender: UITextField) {
    }

    @objc private func textFieldEndedEditing(_ sender: UITextField) {
        finalizeEditing()
    }

    @objc private func textFieldDidChange(_ sender: UITextField) {
        tokenValue = sender.text ?? ""
    }

    @objc private func textFieldDidEndOnExit(_ sender: UITextField) {
        sender.resignFirstResponder()
    }

    @objc private func keyboardWasShown(_ notification: Notification) {
        guard let info = notification.userInfo,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let kbSize = view.convert(keyboardFrame.cgRectValue, from: nil).size

        UIView.animate(withDuration: 0.2, animations: {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: kbSize.height, right: 0.0)
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
        }, completion: { finished in
            guard finished else {
                return
            }
            guard self.editingRow >= 0 else {
                return
            }
            self.tableView.scrollToRow(
                at: IndexPath(row: self.editingRow, section: 0),
                at: .bottom,
                animated: true
            )
        })
    }

    @objc private func keyboardWillBeHidden(_ notification: Notification) {
        UIView.animate(withDuration: 0.2, animations: {
            let contentInsets = UIEdgeInsets.zero
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
        }, completion: { _ in
            // ...
        })
    }

    private func finalizeEditing() {
        guard !isFinalizingEdit else {
            return
        }
        isFinalizingEdit = true
        defer {
            isFinalizingEdit = false
        }
        guard editingRow >= 0, editingRow < tokens.count else {
            editingRow = -1
            editingCell = nil
            return
        }
        tokens[editingRow] = tokenValue
        tokenValue = ""
        let row = editingRow
        editingRow = -1
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        editingCell = nil
    }
}
