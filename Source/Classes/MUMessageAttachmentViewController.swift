// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Displays message attachments including embedded images and links.
/// Allows users to view images in a gallery or open links in the browser.
@objc(MUMessageAttachmentViewController)
@objcMembers
class MUMessageAttachmentViewController: UITableViewController {

    // MARK: - Private Properties

    private var links: [String] = []
    private var images: [UIImage] = []

    // MARK: - Initialization

    @objc(initWithImages:andLinks:)
    init(images: [Any]?, links: [Any]?) {
        self.images = (images as? [UIImage]) ?? []
        self.links = (links as? [String]) ?? []
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Attachments", comment: "")

        tableView.backgroundView = MUBackgroundView.backgroundView()

        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        let hasImages = !images.isEmpty
        return hasImages ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let hasImages = !images.isEmpty
        if hasImages && section == 0 {
            return 1  // Single row for images section
        } else {
            return links.count
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let hasImages = !images.isEmpty
        if hasImages && section == 0 {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Images", comment: ""))
        } else {
            return MUTableViewHeaderLabel.label(withText: NSLocalizedString("Links", comment: ""))
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return MUTableViewHeaderLabel.defaultHeaderHeight()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        guard let cell = cell else { return UITableViewCell() }

        cell.selectionStyle = .default

        let hasImages = !images.isEmpty
        if hasImages && indexPath.section == 0 {
            // Images row
            if let firstImage = images.first {
                let roundedImage = MUImage.tableViewCellImage(from: firstImage)
                cell.imageView?.image = roundedImage
            }
            cell.textLabel?.text = NSLocalizedString("Images", comment: "")

            let detailText: String
            if images.count == 1 {
                detailText = NSLocalizedString("1 image", comment: "")
            } else {
                detailText = String(format: NSLocalizedString("%lu images", comment: ""), images.count)
            }
            cell.detailTextLabel?.text = detailText
            cell.accessoryType = .disclosureIndicator
        } else {
            // Links row
            cell.imageView?.image = nil
            let urlString = links[indexPath.row]
            if let url = URL(string: urlString) {
                cell.textLabel?.text = url.host
            } else {
                cell.textLabel?.text = urlString
            }
            cell.detailTextLabel?.text = urlString
            cell.accessoryType = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hasImages = !images.isEmpty
        if hasImages && indexPath.section == 0 {
            // Show image viewer
            let imgViewController = MUImageViewController(images: images)
            navigationController?.pushViewController(imgViewController, animated: true)
        } else {
            // Open link
            let urlString = links[indexPath.row]
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
