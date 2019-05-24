//
// The MIT License (MIT)
//
// Copyright © 2019 NoodleOfDeath. All rights reserved.
// NoodleOfDeath
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation fileURLs (the "Software"), to deal
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

import SwiftyFileSystem

extension FileExplorer {

    /// Data structure for a Section in a file explorer table view.
    public class Section: Comparable {
        
        // MARK: - Instance Properties
        
        /// File explorer of this section.
        open weak var fileExplorer: FileExplorer?
        
        /// Resource category of this section. Default is `.regular`.
        public let resourceType: URLFileResourceType
        
        /// Directory of this section.
        public let directoryURL: URL
        
        /// Key used for sorting collections of section instances.
        public let key: String
        
        /// Title of this section.
        public let title: String
        
        /// Index title of this section.
        public let indexTitle: String
        
        /// Documents for this section.
        open var documents: [Document] { didSet { updateHeaderView(for: UIApplication.shared.statusBarOrientation) } }
        
        /// `true` if this section has no documents; `false`, otherwise.
        open var isEmpty: Bool {
            return documents.count == 0
        }
        
        /// Height of this section.
        open var headerHeight: CGFloat {
            guard let _ = fileExplorer?.searchResultsFileExplorer?.directoryURL else { return 20.0 }
            return 40.0
        }
        
        // MARK: - UI Components
        
        /// Header view of this section.
        open lazy var headerView: UIView = {
            let view = UIView()
            let textStyle = fileExplorer?.theme?.textStyle(for: .sectionHeader)
            view.backgroundColor = textStyle?.backgroundColor ?? UIColor(0xEEEEEE)
            view.addSubview(headerViewStackView)
            headerViewStackView.snp.makeConstraints { (dims) in
                dims.top.equalTo(view)
                dims.left.equalTo(view).offset(UIDevice.platform.isIphoneX && UIApplication.shared.statusBarOrientation == .landscapeRight ? 40.0 : 10.0)
                dims.bottom.equalTo(view)
                dims.right.equalTo(view).offset(-40.0)
            }
            return view
        }()
        
        fileprivate lazy var headerViewStackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.addArrangedSubview(headerViewTitleLabel)
            stackView.addArrangedSubview(headerViewSubtitleLabel)
            return stackView
        }()
        
        /// Header view label of this section.
        fileprivate lazy var headerViewTitleLabel: UILabel = {
            let label = UILabel()
            let textStyle = fileExplorer?.theme?.textStyle(for: .sectionHeader)
            label.textAlignment = textStyle?.textAlignment ?? .left
            label.lineBreakMode = textStyle?.lineBreakMode ?? .byTruncatingMiddle
            label.text = String(format: "%@ (%@)", title, FileSystem.localizedString("%d items", with: documents.count))
            label.font = textStyle?.font ?? .boldSystemFont(ofSize: UIFont.systemFontSize)
            label.textColor = textStyle?.textColor ?? UIColor(0x444444)
            return label
        }()
        
        /// Header view label of this section.
        fileprivate lazy var headerViewSubtitleLabel: UILabel = {
            let label = UILabel()
            let textStyle = fileExplorer?.theme?.textStyle(for: .sectionHeader)
            label.textAlignment = textStyle?.textAlignment ?? .left
            label.lineBreakMode = textStyle?.lineBreakMode ?? .byTruncatingMiddle
            label.font = textStyle?.font ?? .boldSystemFont(ofSize: UIFont.systemFontSize)
            label.textColor = textStyle?.textColor ?? UIColor(0x444444)
            label.snp.makeConstraints { (dims) in
                dims.height.equalTo(0.0)
            }
            return label
        }()
        
        // MARK: - Constructor Methods
        
        /// Constructs a new section instance with a specified title, index,
        /// and set of documents.
        ///
        /// - Parameters:
        ///     - fileExplorer: of this section.
        ///     - resourceType: of this section.
        ///     - directory: of this section
        ///     - key: of this section.
        ///     - title: of this section.
        ///     - indexTitle: of this section.
        ///     - documents: of this section.
        public init(fileExplorer: FileExplorer? = nil, resourceType: URLFileResourceType = .regular,
                    directoryURL: URL, key: String, title: String? = nil, indexTitle: String? = nil, documents: [Document] = []) {
            self.fileExplorer = fileExplorer
            self.directoryURL = directoryURL
            self.resourceType = resourceType
            self.key = key
            self.title = title ?? key
            self.indexTitle = indexTitle ?? key
            self.documents = documents
        }
        
        // MARK: - Static Methods
        
        public static func < (lhs: Section, rhs: Section) -> Bool {
            return
                (lhs.resourceType == .directory && rhs.resourceType == .regular) ||
                    (lhs.resourceType == rhs.resourceType && lhs.key < rhs.key)
        }
        
        public static func == (lhs: Section, rhs: Section) -> Bool {
            return
                lhs.resourceType == rhs.resourceType &&
                    lhs.key == rhs.key
        }
        
        // MARK: - Instance Methods
        
        /// Adds a document to this section.
        ///
        /// - Parameters:
        ///     - document: to add to this section.
        ///     - autoSort: specify `true` if `sort()` should be called
        /// immediately after executing this operation. Default is `false`.
        open func add(document: Document, autoSort: Bool = false) {
            documents.append(document)
            if autoSort { sort() }
        }
        
        /// Inserts a document to this section at a specified index.
        ///
        /// - Parameters:
        ///     - document: to add to this section.
        ///     - index: at which to insert the document.
        ///     - autoSort: specify `true` if `sort()` should be called
        /// immediately after executing this operation. Default is `false`.
        open func insert(document: Document, at index: Int, autoSort: Bool = false) {
            documents.insert(document, at: index)
            if autoSort { sort() }
        }
        
        /// Removes all instances of a document from this section.
        ///
        /// - Parameters:
        ///     - document: to remove from this section.
        ///     - autoSort: specify `true` if `sort()` should be called
        /// immediately after executing this operation. Default is `false`.
        open func remove(document: Document, autoSort: Bool = false) {
            documents.removeAll { $0.fileURL == document.fileURL }
            if autoSort { sort() }
        }
        
        /// Removes a document at a specified index.
        ///
        /// - Parameters:
        ///     - index: of the document to remove.
        ///     - autoSort: specify `true` if `sort()` should be called
        /// immediately after executing this operation. Default is `false`.
        @discardableResult
        open func removeDocument(at index: Int, autoSort: Bool = false) -> Document {
            let document = documents.remove(at: index)
            if autoSort { sort() }
            return document
        }
        
        /// Sorts the documents in this section alphabetically.
        open func sort() { documents.sort { $0.filename < $1.filename } }
        
        /// Updates the header view of this section.
        open func updateHeaderView(for orientation: UIInterfaceOrientation) {
            var directoryPrefix = ""
            if let directoryPath = fileExplorer?.searchResultsFileExplorer?.rootFileExplorer.directoryURL?.path {
                let sectionPath = directoryURL.deletingLastPathComponent().path
                directoryPrefix = sectionPath.replacingOccurrences(of: directoryPath, with: "",
                                                                   options: .regularExpression, range: sectionPath.range)
                headerViewSubtitleLabel.text = String(format: "in %@", URL(fileURLWithPath: directoryPrefix).path)
                headerViewSubtitleLabel.snp.updateConstraints { (dims) in
                    dims.height.equalTo(20.0)
                }
            } else {
                headerViewSubtitleLabel.text = ""
                headerViewSubtitleLabel.snp.updateConstraints { (dims) in
                    dims.height.equalTo(0.0)
                }
            }
            headerViewTitleLabel.text = String(format: "%@ (%@)", title,
                                               FileSystem.localizedString("%d items", with: documents.count))
            if !UIDevice.platform.isIphoneX { return }
            guard let superview = headerViewStackView.superview else { return }
            headerViewStackView.snp.updateConstraints { (dims) in
                dims.top.equalTo(superview)
                dims.left.equalTo(superview).offset(orientation == .landscapeRight ? 40.0 : 10.0)
                dims.bottom.equalTo(superview)
                dims.right.equalTo(superview).offset(-40.0)
            }
        }
        
    }

}
