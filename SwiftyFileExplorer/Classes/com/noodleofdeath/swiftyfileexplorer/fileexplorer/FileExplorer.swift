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

import UIKit

import SnapKit
import SwiftyFileSystem
import SwiftyTextStyles
import SwiftyTableFormsUI

/// Provides a view controller implementation that allows for the browsing,
/// modification, and selection of fileURLs, directories, and/or symbolic links
/// using an intuitive table view display.
@objc
open class FileExplorer: UIViewController {
    
    public typealias This = FileExplorer
    
    /// Enumerated type for different fileExplorer layout styles.
    public enum Style {
        
        /// Default style that uses a navigation controller with a view
        /// controller stack for each directory level.
        case normal
        
        /// Style that allows for directories to display their contents within
        /// the same table view as a cascading tree (uses more memory and
        /// computing power).
        case cascading
        
    }

    // MARK: - Instance Properties
    
    override open var prefersStatusBarHidden: Bool {
        return false
    }
    
    /// Status text of this title
    open var statusText: String? {
        didSet { statusBarLabel.text = statusText }
    }
    
    /// Delegate object that responds to events spawned by `FileExplorer`
    /// instances.
    open weak var delegate: FileExplorerDelegate?
    
    /// Root file explorer with no parents.
    open var rootFileExplorer: FileExplorer {
        return parentFileExplorer?.rootFileExplorer ?? searchResultsFileExplorer?.rootFileExplorer ?? self
    }
    
    /// `true` if this file explorer has no parent file explorer and no
    /// search results file explorer.
    open var isRootFileExplorer: Bool {
        return parentFileExplorer == nil && searchResultsFileExplorer == nil
    }
    
    /// Parent file explorer linked to this one, if `layout` is set to `normal`,
    /// and this file explorer has a preceding file explorer parent directory.
    open weak var parentFileExplorer: FileExplorer?
    
    open weak var searchResultsFileExplorer: FileExplorer?
    
    fileprivate var _directoryURL: URL? {
        didSet { loadFromDirectoryURL() }
    }
    
    /// URL of the directory whose contents are to be displayed.
    open var directoryURL: URL? {
        get { return _directoryURL }
        set { _directoryURL = newValue?.resolvingSymlinksInPath() }
    }
    
    /// Path components of this file explorer.
    open var pathComponents: [String] {
        guard let directoryURL = directoryURL else { return  [] }
        if !displayDirectoryRoot,
            let directoryRoot = rootFileExplorer.directoryURL?.path {
            var directoryPath = directoryURL.path
            directoryPath =
                directoryURL.path.replacingOccurrences(of: String(format: "^%@", directoryRoot),
                                                       with: "",
                                                       options: .regularExpression,
                                                       range: directoryPath.range)
            return URL(fileURLWithPath: directoryPath).pathComponents.map{ $0 }
        }
        return directoryURL.pathComponents.map{ $0 }
    }
    
    open class PathBarButton: UIButton {
        
        open var titleAttributes: [NSAttributedStringKey: Any]? {
            didSet { updateTitle() }
        }
        
        open var actionEvent: (() -> ())? {
            didSet { updateTitle() }
        }
        
        @objc
        open func didPress() {
            actionEvent?()
        }
        
        convenience public init(title: String, titleAttributes: [NSAttributedStringKey: Any]? = nil, actionEvent: (() -> ())? = nil) {
            self.init()
            setTitle(title, for: .normal)
            self.actionEvent = actionEvent
            self.titleAttributes = titleAttributes
            updateTitle()
        }
        
        open func updateTitle() {
            var attrs: [NSAttributedStringKey: Any] = [
                .font: UIFont.systemFont(ofSize: 10.0),
                .foregroundColor: UIColor(0x000000),
                ]
            if let titleAttributes = titleAttributes {
                for (key, value) in titleAttributes {
                    attrs[key] = value
                }
            }
            if let _ = actionEvent {
                attrs[.foregroundColor] = UIColor(0x0000FF)
                addTarget(self, action: #selector(didPress), for: .touchUpInside)
            } else {
                removeTarget(self, action: #selector(didPress), for: .touchUpInside)
            }
            if let title = title(for: .normal) {
                let attributedTitle = NSAttributedString(string: title, attributes: attrs)
                setAttributedTitle(attributedTitle, for: .normal)
            }
        }
        
    }
    
    /// Generated subtitle string from `pathComponents`.
    open var pathBarItems: [UIView] {
        var items = [UIView]()
        for i in 0 ..< pathComponents.count {
            let pathComponent = pathComponents[i]
            let barButton = PathBarButton(title: pathComponent)
            items.append(barButton)
            if i + 1  < pathComponents.count {
                if var directoryURL = directoryURL {
                    for _ in i + 1 ..< pathComponents.count {
                        directoryURL = directoryURL.deletingLastPathComponent()
                    }
                    barButton.actionEvent = {
                        self.delegate?.fileExplorer(self, open: Document(fileURL: directoryURL), completionHandler: nil)
                    }
                }
                items.append(PathBarButton(title: "›", titleAttributes: [.font: UIFont.boldSystemFont(ofSize: 14.0)]))
            }
        }
        return items
    }
    
    /// `true` to include the root directory in the path tool bar.
    /// Default is `false`.
    open var displayDirectoryRoot: Bool = false {
        didSet { updatePathBar() }
    }
    
    /// Underlying file urls of this file explorer.
    fileprivate var _fileURLs = [URL]() {
        didSet {
            updateStatusText()
            updateToolbarItems()
        }
    }
    
    /// File URLS contained in the current working directory of this
    /// file explorer.
    open var fileURLs: [URL] {
        get { return _fileURLs }
        set {
            delegate?.fileExplorerWillLoadFileSystem?(self)
            var sectionMap = [String: Section]()
            for fileURL in newValue {
                let document = Document(fileURL: fileURL)
                guard enumerationOptions.filter(url: fileURL)
                    else { continue }
                let key = delegate?.fileExplorer?(self, sectionKeyFor: document) ?? sectionKey(for: document)
                let title = delegate?.fileExplorer?(self, sectionTitleFor: document) ?? sectionTitle(for: document)
                let indexTitle = delegate?.fileExplorer?(self, sectionIndexTitleFor: document) ?? title
                let section = sectionMap[key] ??
                    Section(fileExplorer: self,
                            resourceType: document.absoluteResource.resourceType,
                            directoryURL: fileURL.resolvingSymlinksInPath(),
                            key: key, title: title, indexTitle: indexTitle)
                section.add(document: document)
                sectionMap[key] = section
            }
            self.sectionMap = sectionMap
            delegate?.fileExplorerDidLoadFileSystem?(self)
        }
    }
    
    /// Number of items managed by this file explorer.
    open var itemCount: Int { return fileURLs.count }
    
    /// Search items of this file explorer.
    open var searchItems: [URL]?
    
    /// Surjective mapping between a set of section header names and a set
    /// of `Document` objects sorted alphabetically by filename.
    /// Directory sections will appear before regular file sections.
    open var sectionMap = [String: Section]() {
        didSet {
            sections = sectionMap.map { $1 }.sorted().map
                { $0.sort(); return $0.key }
        }
    }
    
    /// Returns the set of section header names of the current directory,
    /// sorted alphabetically.
    open var sections = [String]() {
        didSet {
            sectionTitles = sections.map { sectionMap[$0]?.title ?? "" }
            sectionIndexTitles = sections.map
                { sectionMap[$0]?.indexTitle ?? "" }
            var fileURLs = [URL]()
            for sectionName in sections {
                guard let section = sectionMap[sectionName] else { continue }
                fileURLs.append(contentsOf:
                    section.documents.map { $0.fileURL })
            }
            _fileURLs = fileURLs
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    /// Returns the set of section header names of the current directory,
    /// sorted alphabetically.
    open var sectionTitles = [String]()
    
    /// Returns the set of section header names of the current directory,
    /// sorted alphabetically.
    open var sectionIndexTitles = [String]()
    
    /// Directory enumeration used for deciding what types of fileURLs to make
    /// visible.
    open var enumerationOptions: FileManager.DirectoryEnumerationOptions = []
        { didSet { loadFromDirectoryURL() } }
    
    /// Indicates the max image file size allowed for generating thumbnails.
    /// Default value is 2MB (2000 * 1024).
    open var maxThumbnailFileSize: Double = DataSizeUnit.Megabyte * 4 {
        didSet { tableView.reloadData() }
    }
    
    /// Presentation style of this file explorer.
    open var style: Style = .normal {
        didSet { }
    }
    
    /// The number of table rows at which to display the index list on the
    /// right edge of the table.
    open var sectionIndexMinimumDisplayRowCount: Int = 30 {
        didSet { tableView.sectionIndexMinimumDisplayRowCount =
            sectionIndexMinimumDisplayRowCount }
    }
    
    /// File explorer theme used when displaying the table view.
    open var theme: FileExplorer.Theme? = .default {
        didSet { tableView.reloadData() }
    }
    
    /// Number of fileURLs currently selected in the table view of this
    /// file explorer.
    open var selectedItemCount: Int {
        return (tableView.indexPathsForSelectedRows ?? []).count
    }
    
    /// Selected documents of this file explorer.
    open var selectedDocuments: [Document] {
        return (tableView.indexPathsForSelectedRows ?? []).map
            { self.document(for: $0) }
    }
    
    /// Set this to `true` to make this file explorer searchable.
    open var searchable: Bool = false {
        didSet {

        }
    }
    
    open var isPresentingSearchController: Bool = false {
        didSet { updateToolbarItems() }
    }
    
    // MARK: - UI Components
    
    /// Main stack view of this file explorer.
    fileprivate lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    fileprivate lazy var pathStatusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.addArrangedSubview(pathBarView)
        stackView.addArrangedSubview(statusBar)
        return stackView
    }()
    
    /// Path toolbar view of this file explorer.
    fileprivate lazy var pathBarView: UIView = {
        let view = UIView()
        let textStyle = theme?.textStyle(for: .pathToolBar)
        view.backgroundColor = textStyle?.backgroundColor ?? UIColor(0xEEEEEE)
        view.addConstrainedSubview(pathBarScrollView)
        view.snp.makeConstraints({ (dims) in
            dims.height.equalTo(25.0)
        })
        return view
    }()
    
    /// Path toolbar scroll view of this file explorer.
    fileprivate lazy var pathBarScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        let paddedView = UIView()
        paddedView.addConstrainedSubview(pathBarStackView, 0.0, 10, 0.0, -10.0)
        paddedView.snp.makeConstraints({ (dims) in
            dims.height.equalTo(25.0)
        })
        scrollView.addSubview(paddedView)
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    /// Path toolbar stack view of this file explorer.
    fileprivate lazy var pathBarStackView: UIStackView = {
        let stackView = UIStackView()
        return stackView
    }()
    
    /// Status bar view of this file explorer.
    fileprivate lazy var statusBar: UIView = {
        let view = UIView()
        let textStyle = theme?.textStyle(for: .statusBar)
        view.backgroundColor = textStyle?.backgroundColor ?? UIColor(0xAAAAAA)
        let stackView = UIStackView()
        stackView.addArrangedSubview(statusBarLabel)
        view.addSubview(stackView)
        stackView.constrainToSuperview()
        view.snp.makeConstraints({ (dims) in
            dims.height.equalTo(25.0)
        })
        return view
    }()
    
    /// Status bar label of this file explorer.
    fileprivate lazy var statusBarLabel: UILabel = {
        let label = UILabel()
        let textStyle = theme?.textStyle(for: .statusBar)
        label.textAlignment = textStyle?.textAlignment ?? .center
        label.lineBreakMode = textStyle?.lineBreakMode ?? .byTruncatingMiddle
        return label
    }()
    
    /// Table view that will display the contents of this file explorer.
    fileprivate var tableView: UITableView
    
    /// Creates a new table view intialized with `tableStyle`.
    fileprivate class func autogeneratedTableView(withStyle tableStyle: UITableView.Style) ->  UITableView {
        let tableView = UITableView(frame: .zero, style: tableStyle)
        tableView.allowsMultipleSelection = false
        tableView.allowsMultipleSelectionDuringEditing = true
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        tableView.register(
            FileExplorerTableViewCell.self,
            forCellReuseIdentifier: String(FileExplorerTableViewCell.hash()))
        return tableView
    }
    
    /// Search controller of this file explorer.
    fileprivate var _searchController: UISearchController?
    
    /// Search controller that will appear as the table view header of this
    /// file exploer.
    open fileprivate (set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        searchController.edgesForExtendedLayout = []
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.spellCheckingType = .no
        searchController.searchBar.scopeButtonTitles = ["Local", "Subdirectories", "All Files"]
        searchController.searchBar.height = 44.0
        return searchController
    }()
    
    /// Search results controller of this file explorer.
    fileprivate lazy var searchResultsController: FileExplorer = {
        let fileExplorer = FileExplorer() 
        fileExplorer.delegate = delegate
        fileExplorer.searchResultsFileExplorer = self
        return fileExplorer
    }()
    
    /// Document interaction controller of this file explorer.
    fileprivate lazy var interactionController: UIDocumentInteractionController = {
        let interactionController = UIDocumentInteractionController()
        interactionController.delegate = self
        return interactionController
    }()
    
    // MARK: - Constructor Methods
    
    /// Constructs a new file explorer instance with an initial set of file
    /// urls and table view style.
    ///
    /// - Parameters:
    ///     - fileURLs: to initialize this file explorer with.
    ///     - style: to use to display the table view of this file explorer.
    required public init(fileURLs: [URL]? = nil, style: UITableView.Style = .plain) {
        tableView = This.autogeneratedTableView(withStyle: style)
        super.init(nibName: nil, bundle: nil)
        self.fileURLs ?= fileURLs
    }
    
    /// Constructs a new file explorer instance with the file urls contained
    /// in a specified directory URL and table view style.
    ///
    /// - Parameters:
    ///     - directoryURL: of the directory to enumerate the file URLs of.
    ///     - style: to use to display the table view of this file explorer.
    public convenience init(directoryURL: URL, style: UITableView.Style = .plain) {
        self.init(fileURLs: nil, style: style)
        self.directoryURL = directoryURL
        loadFromDirectoryURL()
    }
    
    /// Returns an object initialized from data in a given unarchiver.
    ///
    /// - Parameters:
    ///     - decoder: An unarchiver object.
    /// - Returns:
    ///     `self`, initialized using the data in `decoder`.
    required public init?(coder decoder: NSCoder) {
        tableView = This.autogeneratedTableView(withStyle: .plain)
        super.init(coder: decoder)
    }
    
    // MARK: - UIViewController Methods
    
    override open func viewDidLoad() {
        
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge()
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = false
        navigationController?.hidesBarsOnTap = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexMinimumDisplayRowCount = sectionIndexMinimumDisplayRowCount
        
        mainStackView.addArrangedSubview(tableView)
        mainStackView.addArrangedSubview(pathStatusStackView)
        
        view.addConstrainedSubview(mainStackView)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: NSNotification.Name.UIKeyboardWillChangeFrame,
            object: nil)
        
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.fileExplorer?(self, viewWillAppear: animated)
        navigationController?.hidesBarsOnTap = false
        loadFromDirectoryURL()
        updatePathBar()
        updateStatusText()
        updateToolbarItems()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.fileExplorer?(self, viewDidAppear: animated)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.fileExplorerViewWillDisappear?(self)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.fileExplorerViewDidDisappear?(self)
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIKeyboardWillChangeFrame,
            object: nil)
    }
    
    override open func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        tableView.tableHeaderView = editing ? nil : searchController.searchBar
        updateStatusText()
        updateToolbarItems(animated: animated)
        delegate?.fileExplorer?(self, didChangeEditingMode: animated)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateToolbarItems()
            for sectionName in self.sections {
                guard let section = self.sectionMap[sectionName] else { continue }
                section.updateHeaderView(for: UIApplication.shared.statusBarOrientation)
            }
            if let superview = self.pathBarScrollView.superview {
                let offset = UIApplication.shared.statusBarOrientation == .landscapeRight ? 40.0 : 0.0
                self.pathBarScrollView.snp.updateConstraints({ (dims) in
                    dims.top.equalTo(superview)
                    dims.left.equalTo(superview).offset(offset)
                    dims.bottom.equalTo(superview)
                    dims.right.equalTo(superview)
                })
            }
        })
    }
    
}

// MARK: - UITableViewDataSource Methods
extension FileExplorer: UITableViewDataSource {
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionMap[sections[section]]?.documents.count ?? 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(FileExplorerTableViewCell.hash()), for: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? FileExplorerTableViewCell else { return }
        
        let document = self.document(for: indexPath)
        
        let textStyle = document.isHidden() ?
            theme?.textStyle(for: .hidden) :
            theme?.textStyle(for: document.resourceType) + theme?.textStyle(for: document.absoluteResource)
        
        cell.delegate = self
        
        cell.title = document.displayName
        cell.titleColor = textStyle?.textColor ?? (document.isHidden() ? .lightGray : .black)
        cell.iconTintColor = textStyle?.iconTintColor ?? .black
        cell.iconAlpha = textStyle?.iconAlpha ?? 1.0
        cell.iconShadow = textStyle?.iconShadow ?? NSShadow()
        
        switch document.absoluteResource.resourceType {
            
        case .directory:
            cell.accessoryType = .detailDisclosureButton
            cell.iconImage = theme?.thumbnail(for: .directory)
            cell.leftSubtitle = FileSystem.localizedString("%d items", with: document.absoluteResource.fileCount)
            cell.rightSubtitle = nil
            break
            
        case .regular:
            cell.accessoryType = .detailButton
            cell.iconImage =
                document.absoluteResource.thumbnail(with: CGSize(width: 40.0, height: 45.0)) ??
                theme?.thumbnail(for: document.absoluteResource)
            cell.leftSubtitle = document.absoluteResource.fileSize.dataSizeString(decimals: 2)
            cell.rightSubtitle = document.absoluteResource.modificationDate.string()
            break
            
        default:
            cell.accessoryType = .detailButton
            cell.iconImage = theme?.thumbnail(for: .regular)
            cell.leftSubtitle = nil
            cell.rightSubtitle = nil
            break
            
        }
        
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionMap[sections[section]]?.headerHeight ?? 20.0
    }
    
    open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return sectionMap[sections[section]]?.headerHeight ?? 20.0
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionMap[sections[section]]?.headerView
    }
    
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionIndexTitles.index(of: title) ?? NSNotFound
    }
    
    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if let editActions =
            delegate?.fileExplorer?(self,
                                    editActionsForRowAt: indexPath,
                                    tableView: tableView,
                                    document: self.document(for: indexPath)) { return editActions }
        return defaultEditActionsForRow(at: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45.0
    }
    
}

// MARK: - UITableViewDelegate Methods
extension FileExplorer: UITableViewDelegate {
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = self.document(for: indexPath)
        delegate?.fileExplorer?(self,
                                didSelectRowAt: indexPath,
                                tableView: tableView,
                                document: document)
        if isEditing {
            updateStatusText()
            updateToolbarItems()
        } else {
           
        }
    }
    
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let document = self.document(for: indexPath)
        delegate?.fileExplorer?(self,
                                didDeselectRowAt: indexPath,
                                tableView: tableView,
                                document: document)
        if isEditing {
            updateStatusText()
            updateToolbarItems()
        } else {
            
        }
    }
    
    open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let document = self.document(for: indexPath)
        delegate?.fileExplorer?(self,
                                didSelectRowAt: indexPath,
                                tableView: tableView,
                                barButtonItem: (tableView.cellForRow(at: indexPath) as? FileExplorerTableViewCell)?.barButtonItem,
                                document: document)
    }
    
}

// MARK: - UIAlertViewDelegate Methods
extension FileExplorer: UIAlertViewDelegate {
    
}

// MARK: - UISearchBarDelegate Methods
extension FileExplorer: UISearchBarDelegate {
    
    open func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: searchController)
    }
    
}

// MARK: - UISearchResultsUpdating Methods
extension FileExplorer: UISearchResultsUpdating {
    
    open func updateSearchResults(for searchController: UISearchController) {
        guard let resultsController = searchController.searchResultsController as? FileExplorer else { return }
        if let searchText = searchController.searchBar.text {
            DispatchQueue.main.async {
                var searchItems = self.searchItems
                if searchItems == nil {
                    searchItems = [URL]()
                    switch searchController.searchBar.selectedScopeButtonIndex {
                        
                    case 1:
                        for fileURL in self.fileURLs {
                            searchItems?.append(contentsOf: self.enumerate(fileURL: fileURL))
                        }
                        break
                        
                    case 2:
                        if let rootDirectoryURL = self.rootFileExplorer.directoryURL {
                            searchItems?.append(contentsOf: self.enumerate(fileURL: rootDirectoryURL))
                        }
                        break
                        
                    default:
                        searchItems = self.fileURLs
                        break
                        
                    }
                }
                DispatchQueue.main.async {
                    resultsController.fileURLs = searchItems?.filter { searchText.doesMatch($0.lastPathComponent) } ?? []
                }
            }
        } else {
            resultsController.fileURLs = []
        }
    }
    
    open func enumerate(fileURL: URL) -> [URL] {
        var fileURLs = [fileURL]
        guard fileURL.isDirectory else { return fileURLs }
        for fileURL in FileSystem.contentsOfDirectory(at: fileURL) {
            fileURLs.append(contentsOf: enumerate(fileURL: fileURL))
        }
        return fileURLs
    }
    
}

// MARK: - UISearchControllerDelegate Methods
extension FileExplorer: UISearchControllerDelegate {
    
    open func presentSearchController(_ searchController: UISearchController) {
        present(searchController, animated: true)
    }
    
    open func willPresentSearchController(_ searchController: UISearchController) {
        
    }
    
    open func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    open func didPresentSearchController(_ searchController: UISearchController) {
        isPresentingSearchController = true
    }
    
    open func didDismissSearchController(_ searchController: UISearchController) {
        isPresentingSearchController = false
    }
    
}

// MARK: - FileExplorerTableViewCellDelegate Methods
extension FileExplorer: FileExplorerTableViewCellDelegate {
    
    open func didRecognize(singleTapGesture: UITapGestureRecognizer, in cell: FileExplorerTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let document = self.document(for: indexPath)
        delegate?.fileExplorer?(self,
                                didSelectRowAt: indexPath,
                                tableView: tableView,
                                document: document)
        if isEditing {

        } else {
            delegate?.fileExplorer(self, open: document, completionHandler: nil)
        }
    }
    
    open func didRecognize(doubleTapGesture: UITapGestureRecognizer, in cell: FileExplorerTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let document = self.document(for: indexPath)
        delegate?.fileExplorer?(self,
                                didDoubleTapRowAt: indexPath,
                                tableView: tableView,
                                document: document)
        
    }
    
    open func didRecognize(longPressGesture: UILongPressGestureRecognizer, in cell: FileExplorerTableViewCell) {
        
        guard longPressGesture.state == .began, let indexPath = tableView.indexPath(for: cell)
            else { return }
        
        let document = self.document(for: indexPath)
        delegate?.fileExplorer?(self,
                                didPressAndHoldRowAt: indexPath,
                                tableView: tableView,
                                document: document)
        
        let actionSheet = UIAlertController(title: document.filename,
                                            message: pathComponents.joined(separator: " › "),
                                            preferredStyle: .actionSheet)
        
        let actions =
            delegate?.fileExplorer?(self,
                                    longPressActionsForRowAt: indexPath,
                                    tableView: tableView,
                                    document: document,
                                    presentingViewController: actionSheet) ??
                defaultLongPressActionsForRow(at: indexPath,
                                              tableView: tableView,
                                              document: document,
                                              presentingViewController: actionSheet)
        
        actions.forEach { actionSheet.addAction($0) }
        view.window?.rootViewController?.present(actionSheet, animated: true)
        
    }
    
}

extension FileExplorer {
    
    @objc
    open func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard let superview = searchResultsController.view.superview else { return }
        searchResultsController.view.snp.updateConstraints { (dims) in
            let offset = keyboardFrame.origin.y < UIScreen.main.bounds.height ? -(superview.height + superview.y - keyboardFrame.origin.y) : 0.0
            dims.bottom.equalTo(superview).offset(offset)
        }
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            superview.layoutIfNeeded()
        }
    }
    
}

// MARK: - Instance Methods
extension FileExplorer {
    
    /// Default section index value for a document.
    ///
    /// - Parameters:
    ///     - document: to generate a section index for.
    open func sectionKey(for document: Document) -> String  {
        return String(format: "%@%@%@",
                      document.absoluteResource.isDirectory ? "📁 " : "",
                      document.filename.firstCharacter.uppercased(),
                      document.fileURL.deletingLastPathComponent().path)
    }
    
    /// Default section title value for a document.
    ///
    /// - Parameters:
    ///     - document: to generate a section index for.
    open func sectionTitle(for document: Document) -> String  {
        return String(format: "%@%@",
                      document.absoluteResource.isDirectory ? "📁 " : "",
                      document.filename.firstCharacter.uppercased())
    }
    
    /// Returns the section for the given document.
    open func section(for document: Document) -> Section? {
        let sectionKey = delegate?.fileExplorer?(self, sectionKeyFor: document) ?? self.sectionKey(for: document)
        return sectionMap[sectionKey]
    }
    
    /// Returns the documents contained in a particular section.
    ///
    /// - Parameters:
    ///     - section: Index of the section whose documents are to be
    /// returned.
    /// - Returns: The documents contained in the section located specified
    /// index or an empty collections if no such section exists.
    open func documentsIn(section: Int) -> [Document] {
        return sectionMap[sections[section]]?.documents ?? []
    }
    
    /// Returns the document located at a given index path.
    ///
    /// - Parameters:
    ///     - indexPath: Index path of the document to return.
    /// - Returns: The document located at `indexPath` or `nil` if no such
    /// document exists.
    open func document(for indexPath: IndexPath) -> Document {
        return documentsIn(section: indexPath.section)[indexPath.row]
    }
    
    open func documents(for indexPaths: [IndexPath]) -> [Document] {
        return indexPaths.map { self.document(for: $0) }
    }
    
    /// Updates the itemsystem and reloads the table view display.
    open func loadFromDirectoryURL() {
        
        guard let directoryURL = directoryURL else {
            print("WARNING: Directory URL is not set for file explorer.")
            return
        }
        
        title = isRootFileExplorer ? "/" : directoryURL.lastPathComponent
        updatePathBar()
        
        let workingDirectory = Document(fileURL: directoryURL)
        guard workingDirectory.isDirectory else {
            print(String(format: "Supplied URL \"%@\" is not a directory. %@",
                         directoryURL.absoluteString,
                         "Unable to load itemsystem contents as a result."))
            return
        }
        
        fileURLs = FileSystem.contentsOfDirectory(at: directoryURL)
        
    }
    
    /// Updates the path tool bar of this file explorer.
    open func updatePathBar() {
        pathBarStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var width: CGFloat = 0.0
        pathBarItems.forEach {
            self.pathBarStackView.addArrangedSubview($0)
            width += $0.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: 25.0)).width
        }
        let contentSize = CGSize(width: width + 20.0, height: 25.0)
        pathBarScrollView.contentSize = contentSize
        pathBarScrollView.contentOffset = CGPoint(x: max(0, contentSize.width - pathBarScrollView.width), y: 0)
    }
    
    /// Updates the toolbar items of this file explorer.
    ///
    /// - Parameters:
    ///     - animated: specify `true` to animate this update. Default is
    /// `false`.
    open func updateToolbarItems(animated: Bool = false) {
        let toolBarItems = delegate?.toolbarItems?(forFileExplorer: self)
        setToolbarItems(toolBarItems, animated: animated)
    }
    
    /// Updates the status bar text.
    open func updateStatusText() {
        statusText = delegate?.statusText?(forFileExplorer: self)
    }
    
    ///
    open func defaultEditActionsForRow(at indexPath: IndexPath) -> [UITableViewRowAction] {
        
        var editActions = [UITableViewRowAction]()
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: FileExplorer.localizedString("delete").capitalized) { (_, _) in
            self.removeDocuments(for: [indexPath])
        }
        editActions.append(deleteAction)
        
        let renameAction = UITableViewRowAction(style: .default, title: FileExplorer.localizedString("rename").capitalized) { (_, _) in
            self.renameDocument(for: indexPath)
        }
        renameAction.backgroundColor = .blue
        editActions.append(renameAction)
        
        return editActions
        
    }
    
    ///
    open func defaultLongPressActionsForRow(at indexPath: IndexPath, tableView: UITableView, document: Document, presentingViewController: UIViewController) -> [UIAlertAction] {
        
        var actions = [UIAlertAction]()
        
        let actionOpenIn =
            (UIAlertAction(title: FileExplorer.localizedString("open in...").capitalized,
                           style: .default)
            { _ in
                self.showDocumentIC(for: document,
                                    from: (tableView.cellForRow(at: indexPath) as? FileExplorerTableViewCell)?.barButtonItem)
            })
        actions.append(actionOpenIn)
        
        let actionRename =
            UIAlertAction(title: FileExplorer.localizedString("rename").capitalized,
                          style: .default) { _ in self.renameDocument(for: indexPath) }
        actions.append(actionRename)
        
        let actionCancel =
            UIAlertAction(title: FileExplorer.localizedString("cancel").capitalized,
                          style: .cancel) { _ in presentingViewController.dismiss(animated: true) }
        actions.append(actionCancel)
        
        return actions
        
    }
    
    /// This method is called whenever the user tries to delete a document.
    /// The delegate is responsible for deleting document resources and
    /// returning control to the fileExplorer afterwards.
    ///
    /// - Parameters:
    ///     - indexPaths: of the documents to remove.
    open func removeDocuments(for indexPaths: [IndexPath]? = nil) {
        let indexPaths = indexPaths ?? tableView.indexPathsForSelectedRows ?? []
        let documents = indexPaths.map { self.document(for: $0) }
        delegate?.fileExplorer(self, remove: documents) {
            if $0 {
                var removedSections = [(index: Int, name: String)]()
                let indexPaths = indexPaths.sorted { (a, b) -> Bool in
                    return a.section > b.section || (a.section == b.section && a.row > b.row)
                }
                for indexPath in indexPaths {
                    guard let section = self.sectionMap[self.sections[indexPath.section]] else { continue }
                    section.removeDocument(at: indexPath.row)
                    if section.isEmpty {
                        removedSections.insert((indexPath.section, section.key), at: 0)
                    }
                    self.sectionMap[section.key] = section
                }
                self.tableView.deleteRows(at: indexPaths, with: .automatic)
                if removedSections.count > 0 {
                    for removedSection in removedSections {
                        self.sectionMap.removeValue(forKey: removedSection.name)
                    }
                    self.tableView.reloadData()
                }
                self.updateStatusText()
            }
        }
    }
    
    /// Presents a rename document alert controller for a specified index path.
    ///
    /// - Parameters:
    ///     - indexPath: of the document to rename.
    open func renameDocument(for indexPath: IndexPath) {
        
        let document = self.document(for: indexPath)
        let alert = UIAlertController(title: String(format: "%@ %@", FileExplorer.localizedString("rename").capitalized, document.filename), message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = document.filename
        }
        
        let actionRename = UIAlertAction(title: FileExplorer.localizedString("rename").capitalized,
                                         style: .default)
        { _ in
            alert.dismiss(animated: true)
            guard
                let textField = alert.textFields?.first,
                let directoryURL = self.directoryURL,
                let filename = textField.text,
                filename.length > 0, filename != document.filename
                else { return }
            let destinationURL = directoryURL +/ filename
            self.delegate?.fileExplorer(self, move: [document], to: destinationURL) { _ in
                self.loadFromDirectoryURL()
            }
        }
        alert.addAction(actionRename)
        
        let actionCancel = UIAlertAction(title: FileExplorer.localizedString("cancel").capitalized,
                                         style: .default) { _ in alert.dismiss(animated: true) }
        alert.addAction(actionCancel)
        
        view.window?.rootViewController?.present(alert, animated: true)
        
    }
    
    /// Selects all documents in the current directory.
    open func selectAll() {
        guard isEditing else { return }
        for i in 0 ..< sectionMap.count {
            for j in 0 ..< documentsIn(section: i).count {
                tableView.selectRow(at: IndexPath(row: j, section: i), animated: true, scrollPosition: .none)
            }
        }
    }
    
    /// Deselects all documents in the current directory.
    open func deselectAll() {
        guard isEditing else { return }
        for i in 0 ..< sectionMap.count {
            for j in 0 ..< documentsIn(section: i).count {
                tableView.deselectRow(at: IndexPath(row: j, section: i), animated: true)
            }
        }
    }
    
    /// Selects the inverse of the current selection in the current directory.
    open func invertSelection() {
        guard isEditing else { return }
        for i in 0 ..< sectionMap.count {
            for j in 0 ..< documentsIn(section: i).count {
                let indexPath = IndexPath(row: j, section: i)
                guard let cell = tableView.cellForRow(at: indexPath) else { continue }
                cell.isSelected ?
                    tableView.deselectRow(at: indexPath, animated: true) :
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }
    
    /// Displays a document interaction controller for a specified document.
    ///
    /// - Parameters:
    ///     - document: to show a document interaction controller for.
    ///     - barButtonItem: to show the document interaction controller from
    /// if running on an iPad.
    open func showDocumentIC(for document: Document, from barButtonItem: UIBarButtonItem? = nil) {
        interactionController.url = document.fileURL
        switch UIDevice.platform {
            
        case let platform where platform.isPad:
            if let barButtonItem = barButtonItem {
                interactionController.presentOpenInMenu(from: barButtonItem, animated: true)
            } else {
                interactionController.presentOpenInMenu(from: UIScreen.main.bounds, in: view, animated: true)
            }
            break

        default:
            interactionController.presentOpenInMenu(from: UIScreen.main.bounds, in: view, animated: true)
            break
            
        }
    }
    
    ///
    open func makeDocumentVisible(_ document: Document?) {
        guard let document = document else { return }
        guard let section = sectionMap[sectionKey(for: document)] else { return }
        guard let documentIndex = section.documents.firstIndex(of: document) else { return }
        guard let sectionIndex = sections.firstIndex(of: sectionKey(for: document)) else { return }
        let indexPath = IndexPath(row: documentIndex, section: sectionIndex)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
}

// MARK: - UIDocumentInteractionControllerDelegate Methods
extension FileExplorer: UIDocumentInteractionControllerDelegate {
    
}
