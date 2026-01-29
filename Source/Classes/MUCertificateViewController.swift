import UIKit
import CoreServices

class MUCertificateViewController: UITableViewController {
    private var curIdx = 0
    private var persistentRef: Data?
    private var certificates: [MKCertificate] = []
    private var subjectItems: [[String]] = []
    private var issuerItems: [[String]] = []
    private var certTitle: String?
    private var arrows: UISegmentedControl?
    private var allowExportAndDelete = false

    init(persistentRef: Data) {
        super.init(style: .grouped)
        self.preferredContentSize = CGSize(width: 320, height: 480)
        if let chains = MUCertificateChainBuilder.buildChain(fromPersistentRef: persistentRef) as? [Any] {
            var certs: [MKCertificate] = []
            if let first = MUCertificateController.certificate(withPersistentRef: persistentRef) {
                certs.append(first)
            }
            for (index, obj) in chains.enumerated() where index > 0 {
                // SecCertificate is a CoreFoundation type bridged as AnyObject
                let secCert = obj as! SecCertificate
                let certData = SecCertificateCopyData(secCert) as Data
                if let cert = MKCertificate(certificate: certData, privateKey: nil) {
                    certs.append(cert)
                }
            }
            certificates = certs
        }
        allowExportAndDelete = true
        curIdx = 0
        self.persistentRef = persistentRef
    }

    init(certificate: MKCertificate) {
        super.init(style: .grouped)
        certificates = [certificate]
        curIdx = 0
        self.preferredContentSize = CGSize(width: 320, height: 480)
    }

    init(certificates certs: [MKCertificate]) {
        super.init(style: .grouped)
        certificates = certs
        curIdx = 0
        self.preferredContentSize = CGSize(width: 320, height: 480)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if arrows == nil {
            let control = UISegmentedControl(items: [UIImage(named: "up.png")!, UIImage(named: "down.png")!])
            control.isMomentary = true
            control.addTarget(self, action: #selector(certificateSwitch(_:)), for: .valueChanged)
            arrows = control
        }
        self.tableView.backgroundView = MUBackgroundView.backgroundView()
        if #available(iOS 7, *) {
            self.tableView.separatorStyle = .singleLine
            self.tableView.separatorInset = .zero
        } else {
            self.tableView.separatorStyle = .none
        }
        let actions = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionClicked(_:)))
        if certificates.count > 1 {
            let segmentedContainer = UIBarButtonItem(customView: arrows!)
            if allowExportAndDelete {
                let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 125, height: 45))
                toolbar.barStyle = .black
                if #available(iOS 11.0, *) {
                    toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
                }
                toolbar.backgroundColor = .clear
                toolbar.setItems([actions, segmentedContainer], animated: false)
                let container = UIBarButtonItem(customView: toolbar)
                navigationItem.rightBarButtonItem = container
            } else {
                navigationItem.rightBarButtonItem = segmentedContainer
            }
        } else if certificates.count == 1 && allowExportAndDelete {
            navigationItem.rightBarButtonItem = actions
        }
        updateCertificateDisplay()
    }

    private func showData(for cert: MKCertificate) {
        var subject: [[String]] = []
        var issuer: [[String]] = []
        let cn = NSLocalizedString("Common Name", comment: "Common Name (CN) of an X.509 certificate")
        let org = NSLocalizedString("Organization", comment: "Organization (O) of an X.509 certificate")
        if let str = cert.subjectItem(MKCertificateItemCommonName) {
            subject.append([cn, str])
            certTitle = str
        } else {
            certTitle = NSLocalizedString("Unknown Certificate", comment: "Title shown when viewing a certificate without a Subject Common Name (CN)")
        }
        if let str = cert.subjectItem(MKCertificateItemOrganization) { subject.append([org, str]) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = cert.notBefore() {
            let str = dateFormatter.string(from: date)
            let notBefore = NSLocalizedString("Not Before", comment: "Not Before date (validity period) of an X.509 certificate")
            subject.append([notBefore, str])
        }
        if let date = cert.notAfter() {
            let str = dateFormatter.string(from: date)
            let notAfter = NSLocalizedString("Not After", comment: "Not After date (validity period) of an X.509 certificate")
            subject.append([notAfter, str])
        }
        if let str = cert.emailAddress() {
            let emailAddr = NSLocalizedString("Email", comment: "Email address of an X.509 certificate")
            subject.append([emailAddr, str])
        }
        if let str = cert.issuerItem(MKCertificateItemCommonName) { issuer.append([cn, str]) }
        if let str = cert.issuerItem(MKCertificateItemOrganization) { issuer.append([org, str]) }
        subjectItems = subject
        issuerItems = issuer
        tableView.reloadData()
    }

    func updateCertificateDisplay() {
        showData(for: certificates[curIdx])
        let indexFmt = NSLocalizedString("%i of %i", comment: "Title for viewing a certificate chain (1 of 2, etc.)")
        navigationItem.title = String(format: indexFmt, curIdx + 1, certificates.count)
        arrows?.setEnabled(curIdx != certificates.count - 1, forSegmentAt: 0)
        arrows?.setEnabled(curIdx != 0, forSegmentAt: 1)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return subjectItems.count
        case 1: return issuerItems.count
        case 2, 3: return 1
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let subject = NSLocalizedString("Subject", comment: "Subject of an X.509 certificate")
        let issuer = NSLocalizedString("Issuer", comment: "Issuer of an X.509 certificate")
        let sha1fp = NSLocalizedString("SHA1 Fingerprint", comment: "SHA1 fingerprint of an X.509 certificate")
        let sha256fp = NSLocalizedString("SHA256 Fingerprint", comment: "SHA256 fingerprint of an X.509 certificate")
        switch section {
        case 0: return MUTableViewHeaderLabel.label(withText: subject)
        case 1: return MUTableViewHeaderLabel.label(withText: issuer)
        case 2: return MUTableViewHeaderLabel.label(withText: sha1fp)
        case 3: return MUTableViewHeaderLabel.label(withText: sha256fp)
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return MUTableViewHeaderLabel.defaultHeaderHeight()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "CertificateViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: identifier)
        cell.selectionStyle = .none
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = false
        cell.backgroundColor = .white
        let section = indexPath.section
        let row = indexPath.row
        if section == 2 {
            let cert = certificates[curIdx]
            if let hex = cert.hexDigest(ofKind: "sha1"), hex.count == 40 {
                cell.textLabel?.text = hex
                cell.textLabel?.textColor = MUColor.selectedTextColor()
                cell.textLabel?.font = UIFont(name: "Courier", size: 16)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.lineBreakMode = .byWordWrapping
                cell.selectionStyle = .default
            }
        } else if section == 3 {
            let cert = certificates[curIdx]
            if let hex = cert.hexDigest(ofKind: "sha256"), hex.count == 64 {
                cell.textLabel?.text = hex
                cell.textLabel?.textColor = MUColor.selectedTextColor()
                cell.textLabel?.font = UIFont(name: "Courier", size: 16)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.lineBreakMode = .byWordWrapping
                cell.selectionStyle = .default
            }
        } else {
            let item: [String]
            if section == 0 { item = subjectItems[row] } else { item = issuerItems[row] }
            cell.textLabel?.text = item[0]
            cell.textLabel?.textColor = .black
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            cell.detailTextLabel?.text = item[1]
            cell.detailTextLabel?.textColor = MUColor.selectedTextColor()
            cell.selectionStyle = .default
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let cert = certificates[curIdx]
            var str: String?
            switch indexPath.section {
            case 0:
                str = subjectItems[indexPath.row][1]
            case 1:
                str = issuerItems[indexPath.row][1]
            case 2:
                str = cert.hexDigest(ofKind: "sha1")
            case 3:
                str = cert.hexDigest(ofKind: "sha256")
            default: break
            }
            if let s = str {
                UIPasteboard.general.setValue(s, forPasteboardType: kUTTypeUTF8PlainText as String)
            }
        }
    }

    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            switch indexPath.section {
            case 0,1,2,3:
                return true
            default:
                return false
            }
        }
        return false
    }

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0,1,2,3: return true
        default: return false
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    @objc func certificateSwitch(_ sender: Any) {
        if let seg = arrows, seg.selectedSegmentIndex == 0 {
            if curIdx < certificates.count - 1 { curIdx += 1 }
        } else {
            if curIdx > 0 { curIdx -= 1 }
        }
        updateCertificateDisplay()
    }

    @objc func actionClicked(_ sender: Any) {
        let cancel = NSLocalizedString("Cancel", comment: "Cancel button for certificate action sheet")
        let delete = NSLocalizedString("Delete", comment: "Delete button for certificate action sheet")
        let export = NSLocalizedString("Export to iTunes", comment: "iTunes export button text for certificate chain action sheet")
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
        sheet.addAction(UIAlertAction(title: delete, style: .destructive) { _ in
            let title = NSLocalizedString("Delete Certificate Chain", comment: "Certificate deletion warning title")
            let msg = NSLocalizedString("Are you sure you want to delete this certificate chain?\n\nIf you don't have a backup, this will permanently remove any rights associated with the certificate chain on any Mumble servers.", comment: "Certificate deletion warning message")
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: delete, style: .default) { _ in
                if let ref = self.persistentRef {
                    MUCertificateController.deleteCertificate(withPersistentRef: ref)
                    self.navigationController?.popViewController(animated: true)
                }
            })
            self.present(alert, animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: export, style: .default) { _ in
            let title = NSLocalizedString("Export Certificate Chain", comment: "Title for certificate export alert view")
            let cancel = NSLocalizedString("Cancel", comment: "Cancel button for certificate export dialog")
            let export = NSLocalizedString("Export", comment: "Export button for certificate export dialog")
            let filename = NSLocalizedString("Filename", comment: "Filename text field in certificate export alert view")
            let password = NSLocalizedString("Password (for importing)", comment: "Password text field in certificate export alert view")
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: export, style: .default) { _ in
                let exportFailedTitle = NSLocalizedString("Export Failed", comment: "Title for UIAlertView when a certificate export fails")
                let cancelButtonText = NSLocalizedString("OK", comment: "Default Cancel button text for UIAlertViews that are shown when certificate export fails.")
                guard let password = alert.textFields?[1].text else { return }
                let data = MKCertificate.exportChain(asPKCS12: self.certificates, withPassword: password)
                guard let pkcsData = data else {
                    let unknown = NSLocalizedString("Mumble was unable to export the certificate.", comment: "Error message shown for a failed export, cause unknown.")
                    let errorAlert = UIAlertController(title: exportFailedTitle, message: unknown, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: cancelButtonText, style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                    return
                }
                var fileName = alert.textFields?[0].text ?? ""
                if URL(fileURLWithPath: fileName).pathExtension.isEmpty {
                    fileName = (fileName as NSString).appendingPathExtension("pkcs12") ?? fileName
                }
                let documentDirs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                if let dir = documentDirs.first {
                    let path = (dir as NSString).appendingPathComponent(fileName)
                    do {
                        try pkcsData.write(to: URL(fileURLWithPath: path), options: .atomic)
                    } catch {
                        let errAlert = UIAlertController(title: exportFailedTitle, message: error.localizedDescription, preferredStyle: .alert)
                        errAlert.addAction(UIAlertAction(title: cancelButtonText, style: .cancel, handler: nil))
                        self.present(errAlert, animated: true, completion: nil)
                    }
                }
            })
            alert.addTextField { $0.placeholder = filename }
            alert.addTextField { $0.isSecureTextEntry = true; $0.placeholder = password }
            self.present(alert, animated: true, completion: nil)
        })
        self.present(sheet, animated: true, completion: nil)
    }
}

