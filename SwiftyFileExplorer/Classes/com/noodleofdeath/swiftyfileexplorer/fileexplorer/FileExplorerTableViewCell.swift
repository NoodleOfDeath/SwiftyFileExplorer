//
// The MIT License (MIT)
//
// Copyright © 2019 NoodleOfDeath. All rights reserved.
// NoodleOfDeath
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

import SnapKit

/// Specifications for a `FileExplorerTableViewCell` delegate.
@objc
public protocol FileExplorerTableViewCellDelegate: class {
    
    /// Called when a table view cell is tapped by the user.
    @objc optional
    func didRecognize(singleTapGesture: UITapGestureRecognizer, in cell: FileExplorerTableViewCell)
    
    /// Called when a table view cell is double tapped by the user.
    @objc optional
    func didRecognize(doubleTapGesture: UITapGestureRecognizer, in cell: FileExplorerTableViewCell)
    
    /// Called when a table view cell is pressed and held by the user.
    @objc optional
    func didRecognize(longPressGesture: UILongPressGestureRecognizer, in cell: FileExplorerTableViewCell)
    
}

/// Custom table view cell to be displayed by a file explorer.
/// Usually displays file/directory name.
@objc
open class FileExplorerTableViewCell: UITableViewCell {

    // MARK: - Instance Properties
    
    /// Delegate fileExplorer object.
    open weak var delegate: FileExplorerTableViewCellDelegate?
    
    /// Edge insets of this cell.
    open var edgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: -10.0, right: -10.0)
    
    /// Main image of this cell.
    open var iconImage: UIImage? {
        didSet { drawIcon() }
    }
    
    /// Image view tint color of this cell.
    open var iconTintColor: UIColor = .black {
        didSet { drawIcon() }
    }
    
    /// Image view alpha of this cell.
    open var iconAlpha: CGFloat = 1.0 {
        didSet { drawIcon() }
    }
    
    open var iconShadow: NSShadow? {
        didSet { drawIcon() }
    }
    
    /// Title of this cell.
    open var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    /// Secondary title of this cell.
    open var secondaryTitle: String? {
        get { return secondaryTitleLabel.text }
        set { secondaryTitleLabel.text = newValue }
    }
    
    /// Subtitle of this table view cell.
    /// Usually displays file size/file count.
    open var leftSubtitle: String? {
        get { return leftSubtitleLabel.text }
        set { leftSubtitleLabel.text = newValue }
    }
    
    /// Subsubtitle of this table view cell.
    /// Usually displays the date modified.
    open var rightSubtitle: String? {
        get { return rightSubtitleLabel.text }
        set { rightSubtitleLabel.text = newValue }
    }
    
    /// Displays the info accessory button.
    open var displayInfoAccessory: Bool = false {
        didSet { layoutIfNeeded() }
    }
    
    /// Color of the title label of this table view cell.
    open var titleColor: UIColor = .black {
        didSet { titleLabel.textColor = titleColor }
    }
    
    /// Select gesture recognizer of this table view cell.
    open lazy var singleTapGesture: UITapGestureRecognizer = {
        let gesture =
            UITapGestureRecognizer(target: self,
                                   action: #selector(didRecognize(singleTapGesture:)))
        gesture.numberOfTapsRequired = 1
        gesture.delegate = self
        return gesture
    }()
    
    /// Double tap gesture recognizer of this table view cell.
    open lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture =
            UITapGestureRecognizer(target: self,
                                   action: #selector(didRecognize(doubleTapGesture:)))
        gesture.numberOfTapsRequired = 2
        gesture.delegate = self
        return gesture
    }()
    
    /// Long press gesture recognizer of this table view cell.
    open lazy var longPressGesture: UILongPressGestureRecognizer = {
        let gesture =
            UILongPressGestureRecognizer(target: self,
                                         action: #selector(didRecognize(longPressGesture:)))
        gesture.minimumPressDuration = 0.3
        gesture.delegate = self
        return gesture
    }()
    
    // MARK: - UI Components
    
    /// Bar button item view of this table view cell.
    open var barButtonItem: UIBarButtonItem {
        return UIBarButtonItem(customView: accessoryView ?? UIView())
    }
    
    /// Stack view of this table view cell.
    fileprivate lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 10.0
        return stackView
    }()
    
    /// Custom image view of this table view cell.
    fileprivate lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    /// Center view of this table view cell.
    fileprivate lazy var mainContentView: UIView = {
        let view = UIStackView()
        view.axis = .vertical
        view.addArrangedSubview(titleView)
        view.addArrangedSubview(subtitleView)
        return view
    }()
    
    /// Title view of this cell.
    fileprivate lazy var titleView: UIView = {
        let view = UIStackView()
        view.addArrangedSubview(titleLabel)
        view.addArrangedSubview(secondaryTitleLabel)
        return view
    }()
    
    /// Meta view of this cell.
    fileprivate lazy var subtitleView: UIView = {
        let view = UIStackView()
        view.addArrangedSubview(leftSubtitleLabel)
        view.addArrangedSubview(rightSubtitleLabel)
        return view
    }()
    
    /// Title label of this cell.
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    /// Secondary title label of this cell.
    fileprivate lazy var secondaryTitleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    /// Subtitle label of this cell.
    fileprivate lazy var leftSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.systemFontSize * 0.75)
        return label
    }()
    
    /// Subsubtitle label of this cell.
    fileprivate lazy var rightSubtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: UIFont.systemFontSize * 0.75)
        return label
    }()
    
    // MARK: - UIView Methods
    
    override open func draw(_ rect: CGRect) {
        
        super.draw(rect)
        
        addGestureRecognizer(singleTapGesture)
        addGestureRecognizer(doubleTapGesture)
        addGestureRecognizer(longPressGesture)
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (dims) in
            dims.top.equalTo(contentView)
            dims.left.equalTo(contentView).offset(15.0)
            dims.bottom.equalTo(contentView)
            dims.right.equalTo(contentView).offset(-15.0)
        }
        
        stackView.addArrangedSubview(iconView)
        iconView.snp.makeConstraints { (dims) in
            dims.width.equalTo(iconImage != nil ? 40.0 : 0.0)
        }
        
        stackView.addArrangedSubview(mainContentView)
        
    }
    
    override open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return
           gestureRecognizer == singleTapGesture &&
            (otherGestureRecognizer == doubleTapGesture || otherGestureRecognizer == longPressGesture)
    }
    
    override open func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            removeGestureRecognizer(singleTapGesture)
            removeGestureRecognizer(doubleTapGesture)
            removeGestureRecognizer(longPressGesture)
        } else {
            addGestureRecognizer(singleTapGesture)
            addGestureRecognizer(doubleTapGesture)
            addGestureRecognizer(longPressGesture)
        }
    }
    
}

// MARK: - Event Handler Methods
extension FileExplorerTableViewCell {
    
    @objc
    /// Called when a double tap gesture is recognized by this cell.
    ///
    /// - Parameters:
    ///     - doubleTapGesture: The long press gesture recognizer.
    fileprivate func didRecognize(singleTapGesture: UITapGestureRecognizer) {
        delegate?.didRecognize?(singleTapGesture: doubleTapGesture, in: self)
    }
    
    @objc
    /// Called when a double tap gesture is recognized by this cell.
    ///
    /// - Parameters:
    ///     - doubleTapGesture: The long press gesture recognizer.
    fileprivate func didRecognize(doubleTapGesture: UITapGestureRecognizer) {
        delegate?.didRecognize?(doubleTapGesture: doubleTapGesture, in: self)
    }
    
    @objc
    /// Called when a long press gesture is recognized by this cell.
    ///
    /// - Parameters:
    ///     - longPressGesture: The long press gesture recognizer.
    fileprivate func didRecognize(longPressGesture: UILongPressGestureRecognizer) {
        delegate?.didRecognize?(longPressGesture: longPressGesture, in: self)
    }
    
}

// MARK: - Instance Methods
extension FileExplorerTableViewCell {
        
    fileprivate func drawIcon() {
        var attributes = [UIImage.CGAttribute: Any]()
        attributes[.tintColor] = iconTintColor
        attributes[.alpha] = iconAlpha
        attributes[.shadow] = iconShadow
        iconView.image = iconImage?.with(attributes: attributes)
    }
        
}
