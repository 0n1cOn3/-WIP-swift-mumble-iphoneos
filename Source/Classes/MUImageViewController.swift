// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Image gallery view controller with paging and zoom support.
/// Displays embedded images from messages with export functionality.
@objc(MUImageViewController)
@objcMembers
class MUImageViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Private Properties

    private var images: [UIImage] = []
    private var imageViews: [UIImageView] = []
    private var scrollView: UIScrollView!
    private var curPage: Int = 0

    // MARK: - Initialization

    @objc(initWithImages:)
    init(images: [Any]?) {
        self.images = (images as? [UIImage]) ?? []
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 44)

        scrollView = UIScrollView(frame: frame)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let contentFrame = CGRect(x: 0, y: 0, width: frame.width * CGFloat(images.count), height: frame.height)
        scrollView.contentSize = contentFrame.size

        var mutableImageViews: [UIImageView] = []

        for i in 0..<images.count {
            let imageFrame = CGRect(x: frame.width * CGFloat(i), y: 0, width: frame.width, height: frame.height)

            let imgZoomer = UIScrollView(frame: imageFrame)
            let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageFrame.width, height: imageFrame.height))
            imgView.image = images[i]
            imgView.contentMode = .scaleAspectFit

            imgZoomer.delegate = self
            imgZoomer.addSubview(imgView)
            imgZoomer.maximumZoomScale = 4.0
            imgZoomer.minimumZoomScale = 1.0
            imgZoomer.showsVerticalScrollIndicator = false
            imgZoomer.showsHorizontalScrollIndicator = false

            scrollView.addSubview(imgZoomer)
            mutableImageViews.append(imgView)
        }

        imageViews = mutableImageViews
        view.addSubview(scrollView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = String(format: NSLocalizedString("%lu of %lu", comment: ""), 1, images.count)

        scrollView.backgroundColor = MUColor.backgroundViewiOS7()

        let actionButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(actionClicked(_:))
        )
        navigationItem.rightBarButtonItem = actionButton
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.scrollView {
            let pt = scrollView.contentOffset
            let pg = Int(pt.x / view.frame.width)
            if pg != curPage {
                curPage = pg
                navigationItem.title = String(format: NSLocalizedString("%lu of %lu", comment: ""), 1 + curPage, images.count)
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView !== self.scrollView && curPage < imageViews.count {
            return imageViews[curPage]
        }
        return nil
    }

    // MARK: - Actions

    @objc private func actionClicked(_ sender: Any) {
        let alertCtrl = UIAlertController(
            title: NSLocalizedString("Export Image", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: nil
        ))

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Export to Photos", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let self = self, self.curPage < self.images.count else { return }
            UIImageWriteToSavedPhotosAlbum(
                self.images[self.curPage],
                self,
                #selector(self.image(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        })

        present(alertCtrl, animated: true, completion: nil)
    }

    @objc private func image(_ img: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        if let error = error {
            let alertCtrl = UIAlertController(
                title: NSLocalizedString("Unable to save image", comment: ""),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alertCtrl.addAction(UIAlertAction(
                title: NSLocalizedString("OK", comment: ""),
                style: .cancel,
                handler: nil
            ))
            present(alertCtrl, animated: true, completion: nil)
        }
    }
}
