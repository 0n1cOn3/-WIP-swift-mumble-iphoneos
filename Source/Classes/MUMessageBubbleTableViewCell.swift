// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

// MARK: - Delegate Protocol

@objc protocol MUMessageBubbleTableViewCellDelegate: AnyObject {
    func messageBubbleTableViewCellRequestedAttachmentViewer(_ cell: MUMessageBubbleTableViewCell)
    func messageBubbleTableViewCellRequestedDeletion(_ cell: MUMessageBubbleTableViewCell)
    func messageBubbleTableViewCellRequestedCopy(_ cell: MUMessageBubbleTableViewCell)
}

// MARK: - Constants

private let balloonWidth: CGFloat             = 190.0
private let balloonTopMargin: CGFloat         = 8.0
private let balloonBottomMargin: CGFloat      = 10.0
private let balloonMarginTailSide: CGFloat    = 19.0
private let balloonMarginNonTailSide: CGFloat = 11.0
private let balloonTopPadding: CGFloat        = 3.0
private let balloonBottomPadding: CGFloat     = 3.0
private let balloonTimestampSpacing: CGFloat  = 5.0
private let balloonTopInset: CGFloat          = 14.0
private let balloonBottomInset: CGFloat       = 17.0
private let balloonTailInset: CGFloat         = 23.0
private let balloonNoTailInset: CGFloat       = 16.0
private let balloonFooterTopMargin: CGFloat   = 2.0
private let balloonFooterBoxPadding: CGFloat  = 2.0
private let balloonImageTopPadding: CGFloat   = 2.0
private let balloonImageBottomPadding: CGFloat = 2.0

// MARK: - MUMessageBubbleView

private class MUMessageBubbleView: UIView {

    var message: String?
    var heading: String?
    var footer: String?
    var date: Date?
    var rightSide: Bool = true
    var imageRect: CGRect = .zero
    var isSelectedState: Bool = false
    var numAttachments: Int = 0
    var shownImages: [UIImage]?
    weak var cell: MUMessageBubbleTableViewCell?

    init(frame: CGRect, tableViewCell: MUMessageBubbleTableViewCell) {
        super.init(frame: frame)
        isOpaque = false
        rightSide = true
        cell = tableViewCell
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Size Calculations

    static func textSize(for text: String?) -> CGSize {
        guard let text = text else { return .zero }
        let constraintSize = CGSize(
            width: balloonWidth - (balloonMarginTailSide + balloonMarginNonTailSide),
            height: .greatestFiniteMagnitude
        )
        let rect = text.boundingRect(
            with: constraintSize,
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 14.0)],
            context: nil
        )
        return rect.size
    }

    static func headingSize(for text: String?) -> CGSize {
        guard let text = text else { return .zero }
        let constraintSize = CGSize(
            width: balloonWidth - (balloonMarginTailSide + balloonMarginNonTailSide),
            height: .greatestFiniteMagnitude
        )
        let rect = text.boundingRect(
            with: constraintSize,
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 14.0)],
            context: nil
        )
        return rect.size
    }

    static func timestampSize(for text: String?) -> CGSize {
        guard let text = text else { return .zero }
        let constraintSize = CGSize(
            width: balloonWidth - (balloonMarginTailSide + balloonMarginNonTailSide),
            height: .greatestFiniteMagnitude
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead
        let rect = text.boundingRect(
            with: constraintSize,
            options: .usesLineFragmentOrigin,
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 11.0),
                .paragraphStyle: paragraphStyle
            ],
            context: nil
        )
        return rect.size
    }

    static func footerSize(for text: String?) -> CGSize {
        guard let text = text else { return .zero }
        let constraintSize = CGSize(
            width: balloonWidth - (balloonMarginTailSide + balloonMarginNonTailSide),
            height: .greatestFiniteMagnitude
        )
        let rect = text.boundingRect(
            with: constraintSize,
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.italicSystemFont(ofSize: 11.0)],
            context: nil
        )
        return rect.size
    }

    static func string(for date: Date?) -> String {
        guard let date = date else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }

    static func imageSize(
        for images: [UIImage]?,
        resizedToFitWithin size: CGSize,
        newImageSizes: inout [CGSize]?
    ) -> CGSize {
        guard let images = images else { return .zero }
        var imageSizes: [CGSize] = []
        var imagesHeight: CGFloat = 0

        for image in images {
            let imgSize = image.size
            if imgSize.width < (size.width - 40) {
                imagesHeight += balloonImageTopPadding + imgSize.height + balloonImageBottomPadding
                imageSizes.append(imgSize)
            } else {
                let w = size.width - 40
                let h = imgSize.height * (w / imgSize.width)
                imagesHeight += balloonImageTopPadding + h + balloonImageBottomPadding
                imageSizes.append(CGSize(width: w, height: h))
            }
        }

        newImageSizes = imageSizes
        return CGSize(width: size.width, height: imagesHeight)
    }

    static func cellSize(
        forText text: String?,
        heading: String?,
        footer: String?,
        date: Date?,
        images: [UIImage]?
    ) -> CGSize {
        let textSize = MUMessageBubbleView.textSize(for: text)
        let headingSize = MUMessageBubbleView.headingSize(for: heading)
        let footerSize = MUMessageBubbleView.footerSize(for: footer)
        let dateStr = MUMessageBubbleView.string(for: date)
        let timestampSize = MUMessageBubbleView.timestampSize(for: dateStr)

        var sz = CGSize(
            width: max(textSize.width, headingSize.width + balloonTimestampSpacing + timestampSize.width) +
                   (balloonMarginTailSide + balloonMarginNonTailSide),
            height: textSize.height + headingSize.height + footerSize.height +
                    (balloonTopMargin + balloonBottomMargin) +
                    (balloonTopPadding + balloonBottomPadding) +
                    (footer != nil ? balloonFooterTopMargin : 0)
        )

        var newSizes: [CGSize]?
        let imgSz = MUMessageBubbleView.imageSize(for: images, resizedToFitWithin: sz, newImageSizes: &newSizes)
        sz.height += imgSz.height
        sz.height = ceil(sz.height)

        return sz
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        var balloon: UIImage?
        var stretchableBalloon: UIImage?

        if #available(iOS 7.0, *) {
            if rightSide {
                balloon = isSelectedState ?
                    UIImage(named: "RightBalloonSelectedMono") :
                    UIImage(named: "Balloon_2_Right")
                stretchableBalloon = balloon?.resizableImage(
                    withCapInsets: UIEdgeInsets(
                        top: balloonTopInset,
                        left: balloonNoTailInset,
                        bottom: balloonBottomInset,
                        right: balloonTailInset
                    )
                )
            } else {
                balloon = isSelectedState ?
                    UIImage(named: "LeftBalloonSelectedMono") :
                    UIImage(named: "Balloon_2")
                stretchableBalloon = balloon?.resizableImage(
                    withCapInsets: UIEdgeInsets(
                        top: balloonTopInset,
                        left: balloonTailInset,
                        bottom: balloonBottomInset,
                        right: balloonNoTailInset
                    )
                )
            }
        } else {
            if rightSide {
                balloon = isSelectedState ?
                    UIImage(named: "RightBalloonSelected") :
                    UIImage(named: "Balloon_Blue")
                stretchableBalloon = balloon?.resizableImage(
                    withCapInsets: UIEdgeInsets(
                        top: balloonTopInset,
                        left: balloonNoTailInset,
                        bottom: balloonBottomInset,
                        right: balloonTailInset
                    )
                )
            } else {
                balloon = isSelectedState ?
                    UIImage(named: "LeftBalloonSelected") :
                    UIImage(named: "Balloon_2")
                stretchableBalloon = balloon?.resizableImage(
                    withCapInsets: UIEdgeInsets(
                        top: balloonTopInset,
                        left: balloonTailInset,
                        bottom: balloonBottomInset,
                        right: balloonNoTailInset
                    )
                )
            }
        }

        let textSize = MUMessageBubbleView.textSize(for: message)
        let headingSize = MUMessageBubbleView.headingSize(for: heading)
        let footerSize = MUMessageBubbleView.footerSize(for: footer)
        let dateStr = MUMessageBubbleView.string(for: date)
        let timestampSize = MUMessageBubbleView.timestampSize(for: dateStr)

        var imgRect = CGRect(
            x: 0.0,
            y: balloonTopPadding,
            width: max(textSize.width, headingSize.width + balloonTimestampSpacing + timestampSize.width) +
                   (balloonMarginTailSide + balloonMarginNonTailSide) + 10,
            height: textSize.height + headingSize.height + footerSize.height +
                    (balloonTopMargin + balloonBottomMargin) +
                    (footer != nil ? balloonFooterTopMargin : 0)
        )
        imgRect = CGRect(
            x: Int(imgRect.minX),
            y: Int(imgRect.minY),
            width: Int(imgRect.width),
            height: Int(imgRect.height)
        )

        var newImageSizes: [CGSize]?
        let imagesSize = MUMessageBubbleView.imageSize(
            for: shownImages,
            resizedToFitWithin: imgRect.size,
            newImageSizes: &newImageSizes
        )
        imgRect.size.height += imagesSize.height
        imgRect.size.height = ceil(imgRect.size.height)

        var headerRect = CGRect(
            x: balloonMarginTailSide,
            y: balloonTopPadding + balloonTopMargin,
            width: headingSize.width,
            height: headingSize.height
        )
        var timestampRect = CGRect(
            x: imgRect.size.width - balloonMarginNonTailSide - timestampSize.width,
            y: headerRect.origin.y,
            width: timestampSize.width,
            height: timestampSize.height
        )
        var textRect = CGRect(
            x: balloonMarginTailSide,
            y: balloonTopPadding + balloonTopMargin + headingSize.height,
            width: textSize.width,
            height: textSize.height
        )

        if rightSide {
            let frameWidth = frame.width
            imgRect.origin.x = frameWidth - imgRect.size.width
            headerRect.origin.x = imgRect.origin.x + balloonMarginNonTailSide
            timestampRect.origin.x = frameWidth - balloonMarginTailSide - timestampRect.size.width
            textRect.origin.x = imgRect.origin.x + balloonMarginNonTailSide
        }

        stretchableBalloon?.draw(in: imgRect)
        imageRect = imgRect

        // Draw images
        let maxWidth = (timestampRect.origin.x + timestampRect.size.width) - headerRect.origin.x
        var shownImgRect = CGRect(x: 0, y: textRect.origin.y + textRect.size.height, width: 0, height: 0)

        if let images = shownImages, let sizes = newImageSizes {
            for (i, shownImage) in images.enumerated() {
                shownImgRect.origin.y += balloonImageTopPadding + shownImgRect.size.height
                let imgSz = sizes[i]
                let leftPad = floor((maxWidth - imgSz.width) / 2)
                shownImgRect.origin.x = textRect.origin.x + leftPad
                shownImgRect.size.width = imgSz.width
                shownImgRect.size.height = imgSz.height
                shownImage.draw(in: shownImgRect)
                shownImgRect.size.height += balloonImageBottomPadding
            }
        }

        let footerRect = CGRect(
            x: textRect.origin.x,
            y: textRect.origin.y + textRect.size.height + imagesSize.height + balloonFooterTopMargin,
            width: footerSize.width,
            height: footerSize.height
        )

        UIColor.black.set()

        // Draw footer
        if let footer = footer {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            footer.draw(in: footerRect, withAttributes: [
                .font: UIFont.italicSystemFont(ofSize: 11.0),
                .paragraphStyle: paragraphStyle
            ])
        }

        // Draw heading
        if let heading = heading {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            heading.draw(in: headerRect, withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 14.0),
                .paragraphStyle: paragraphStyle
            ])
        }

        // Draw timestamp
        let timestampParagraphStyle = NSMutableParagraphStyle()
        timestampParagraphStyle.lineBreakMode = .byTruncatingHead
        dateStr.draw(in: timestampRect, withAttributes: [
            .font: UIFont.italicSystemFont(ofSize: 11.0),
            .paragraphStyle: timestampParagraphStyle
        ])

        // Draw message text
        if let message = message {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            message.draw(in: textRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 14.0),
                .paragraphStyle: paragraphStyle
            ])
        }
    }

    // MARK: - Selection

    func selectionRect() -> CGRect {
        if rightSide {
            return imageRect.inset(by: UIEdgeInsets(
                top: balloonTopMargin,
                left: balloonMarginNonTailSide,
                bottom: balloonBottomMargin,
                right: balloonMarginTailSide
            ))
        } else {
            return imageRect.inset(by: UIEdgeInsets(
                top: balloonTopMargin,
                left: balloonMarginTailSide,
                bottom: balloonBottomMargin,
                right: balloonMarginNonTailSide
            ))
        }
    }

    func setSelectedState(_ selected: Bool) {
        isSelectedState = selected
        setNeedsDisplay()
    }

    // MARK: - First Responder

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFirstResponder {
            UIMenuController.shared.hideMenu()
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) || action == #selector(delete(_:)) {
            return true
        }
        return false
    }

    override func copy(_ sender: Any?) {
        cell?.delegate?.messageBubbleTableViewCellRequestedCopy(cell!)
    }

    override func delete(_ sender: Any?) {
        cell?.delegate?.messageBubbleTableViewCellRequestedDeletion(cell!)
    }
}

// MARK: - MUMessageBubbleTableViewCell

@objc(MUMessageBubbleTableViewCell)
@objcMembers
class MUMessageBubbleTableViewCell: UITableViewCell {

    // MARK: - Properties

    private var bubbleView: MUMessageBubbleView!
    private var longPressRecognizer: UILongPressGestureRecognizer!
    private var tapRecognizer: UITapGestureRecognizer!
    weak var delegate: MUMessageBubbleTableViewCellDelegate?

    // MARK: - Class Methods

    @objc(heightForCellWithHeading:message:images:footer:date:)
    static func heightForCell(
        withHeading heading: String?,
        message: String?,
        images: [UIImage]?,
        footer: String?,
        date: Date?
    ) -> CGFloat {
        return MUMessageBubbleView.cellSize(
            forText: message,
            heading: heading,
            footer: footer,
            date: date,
            images: images
        ).height
    }

    // MARK: - Initialization

    @objc(initWithReuseIdentifier:)
    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        bubbleView = MUMessageBubbleView(frame: contentView.frame, tableViewCell: self)
        bubbleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bubbleView.isUserInteractionEnabled = true
        contentView.addSubview(bubbleView)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(showMenu(_:)))
        bubbleView.addGestureRecognizer(longPressRecognizer)

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showAttachments(_:)))
        bubbleView.addGestureRecognizer(tapRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setters

    func setHeading(_ heading: String?) {
        bubbleView.heading = heading
        bubbleView.setNeedsDisplay()
    }

    func setMessage(_ msg: String?) {
        bubbleView.message = msg
        bubbleView.setNeedsDisplay()
    }

    func setShownImages(_ images: [Any]?) {
        bubbleView.shownImages = images as? [UIImage]
        bubbleView.setNeedsDisplay()
    }

    func setFooter(_ footer: String?) {
        bubbleView.footer = footer
        bubbleView.setNeedsDisplay()
    }

    func setDate(_ date: Date?) {
        bubbleView.date = date
        bubbleView.setNeedsDisplay()
    }

    func setRightSide(_ rightSide: Bool) {
        bubbleView.rightSide = rightSide
        bubbleView.setNeedsDisplay()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        bubbleView.setSelectedState(selected)
    }

    override var isSelected: Bool {
        get { return bubbleView.isSelectedState }
        set { bubbleView.setSelectedState(newValue) }
    }

    // MARK: - Actions

    @objc private func showAttachments(_ sender: Any) {
        if !bubbleView.isSelectedState {
            delegate?.messageBubbleTableViewCellRequestedAttachmentViewer(self)
        }
    }

    @objc private func showMenu(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard bubbleView.canBecomeFirstResponder else { return }

        bubbleView.becomeFirstResponder()
        bubbleView.setSelectedState(true)

        let menuController = UIMenuController.shared
        menuController.showMenu(from: bubbleView, rect: bubbleView.selectionRect())

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuWillHide(_:)),
            name: UIMenuController.willHideMenuNotification,
            object: nil
        )
    }

    @objc private func menuWillHide(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        bubbleView.resignFirstResponder()
        bubbleView.setSelectedState(false)
    }
}
