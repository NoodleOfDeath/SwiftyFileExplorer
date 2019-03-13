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
// THE SOFTWARE

import UIKit

import SnapKit
import SwiftyFileSystem
import SwiftyFileExplorer
import SwiftyTableFormsUI

class ViewController: FileExplorer {
    
    fileprivate var topFileExplorer: FileExplorer {
        return navigationController?.visibleViewController as? FileExplorer ?? self
    }

    enum ClipboardAction {
        case none
        case move
        case copy
    }
    
    var clipboardDocuments = [Document]()
    var clipboardAction: ClipboardAction = .none
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        directoryURL = URL(fileURLWithPath: UserDirectory)
        delegate = self
        searchable = true
        let editBarButtonItem =
            UIBarButtonItem(title: FileExplorer.localizedString("edit").capitalized,
                            style: .plain,
                            target: self,
                            action: #selector(didPress(editBarButtonItem:)))
        navigationItem.rightBarButtonItem = editBarButtonItem
        
    }
    
    func open(_ document: Document, completionHandler: ((Bool) -> ())? = nil) {
        fileExplorer(topFileExplorer, open: document, completionHandler: completionHandler)
    }

}

extension ViewController: FileExplorerDelegate {
    
    func fileExplorer(_ fileExplorer: FileExplorer, toolbarItemsForEditingState isEditing: Bool) -> [UIBarButtonItem] {
        
        var toolbarItems = [UIBarButtonItem]()
        let theme = fileExplorer.theme
        
        if let _ = fileExplorer.searchResultsFileExplorer {
            
            
            
        } else if isEditing {
            
            let deleteBarButtonItem =
                UIBarButtonItem(title: FileExplorer.localizedString("delete").capitalized,
                                style: .plain,
                                target: self,
                                action: #selector(didPress(deleteBarButtonItem:)))
            deleteBarButtonItem.tintColor = .red
            deleteBarButtonItem.isEnabled = fileExplorer.numberOfSelectedItems > 0
            toolbarItems.append(deleteBarButtonItem)
            toolbarItems.append(.flexibleSpace)
            
            let cutBarButtonItem =
                UIBarButtonItem(title: FileExplorer.localizedString("cut").capitalized,
                                style: .plain,
                                target: self,
                                action: #selector(didPress(cutBarButtonItem:)))
            cutBarButtonItem.isEnabled = fileExplorer.numberOfSelectedItems > 0
            toolbarItems.append(cutBarButtonItem)
            toolbarItems.append(.flexibleSpace)
            
            let copyBarButtonItem =
                UIBarButtonItem(title: FileExplorer.localizedString("copy").capitalized,
                                style: .plain,
                                target: self,
                                action: #selector(didPress(copyBarButtonItem:)))
            copyBarButtonItem.isEnabled = fileExplorer.numberOfSelectedItems > 0
            toolbarItems.append(copyBarButtonItem)
            toolbarItems.append(.flexibleSpace)
            
            let pasteCount = clipboardDocuments.count
            let pasteBarButtonItem =
                UIBarButtonItem(title: String(format: "%@ (%d)", FileExplorer.localizedString("paste").capitalized, pasteCount),
                                
                                style: .plain,
                                target: self,
                                action: #selector(didPress(pasteBarButtonItem:)))
            pasteBarButtonItem.isEnabled = pasteCount > 0
            toolbarItems.append(pasteBarButtonItem)
            toolbarItems.append(.flexibleSpace)
            
            let zipBarButtonItem =
                UIBarButtonItem(title: FileExplorer.localizedString("zip").capitalized,
                                style: .plain,
                                target: self,
                                action: #selector(didPress(zipBarButtonItem:)))
            zipBarButtonItem.isEnabled = fileExplorer.numberOfSelectedItems > 0
            toolbarItems.append(zipBarButtonItem)
            
        } else {
            
            let addBarButtonItem =
                UIBarButtonItem(image: theme?.image(named: "add"),
                                style: .plain,
                                target: self,
                                action: #selector(didPress(addBarButtonItem:)))
            toolbarItems.append(addBarButtonItem)
            toolbarItems.append(.flexibleSpace)
            
            let pasteCount = clipboardDocuments.count
            if pasteCount > 0 {
                let pasteBarButtonItem =
                    UIBarButtonItem(title: String(format: "%@ (%d)", FileExplorer.localizedString("paste").capitalized, pasteCount),
                                    
                                    style: .plain,
                                    target: self,
                                    action: #selector(didPress(pasteBarButtonItem:)))
                pasteBarButtonItem.isEnabled = pasteCount > 0
                toolbarItems.append(pasteBarButtonItem)
                toolbarItems.append(.flexibleSpace)
            }
            
            let settingsBarButtonItem =
                UIBarButtonItem(image: theme?.image(named: "settings"),
                                style: .plain,
                                target: self,
                                action: #selector(didPress(settingsBarButtonItem:)))
            toolbarItems.append(settingsBarButtonItem)
            
        }
        
        return toolbarItems
        
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, create document: Document, completionHandler: ((Bool) -> ())?) {
        document.save(to: document.fileURL, for: .forCreating, completionHandler: completionHandler)
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, remove documents: [Document], completionHandler: ((Bool) -> ())?) {
        var successCount = 0
        for document in documents {
            successCount += (FileSystem.removeItem(at: document.fileURL)) ? 1 : 0
        }
        completionHandler?(successCount == documents.count)
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, move documents: [Document], to destinationURL: URL, completionHandler: ((Bool) -> ())?) {
        var successCount = 0
        for document in documents {
            let dst = destinationURL.isDirectory ?
                (destinationURL +/ document.fileURL.lastPathComponent) : destinationURL
            successCount += (FileSystem.moveItem(at: document.fileURL, to: dst) != nil) ? 1 : 0
        }
        completionHandler?(successCount == documents.count)
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, copy documents: [Document], to destinationURL: URL, completionHandler: ((Bool) -> ())?) {
        var successCount = 0
        for document in documents {
            let dst = destinationURL.isDirectory ?
                (destinationURL +/ document.fileURL.lastPathComponent) : destinationURL
            successCount += (FileSystem.copyItem(at: document.fileURL, to: dst) != nil) ? 1 : 0
        }
        completionHandler?(successCount == documents.count)
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, open document: Document, animated: Bool = true, completionHandler: ((Bool) -> ())? = nil) {
        
        let fileExplorer = fileExplorer.searchResultsFileExplorer ?? fileExplorer
        fileExplorer.searchController.dismiss(animated: true, completion: nil)
        
        let document = document.absoluteResource
        
        if let documentViewController = navigationController?.viewControllers.filter ({ ($0 as? FileExplorer)?.directoryURL == document.fileURL }).first {
            
            navigationController?.popToViewController(documentViewController, animated: animated)
            
        } else {
            
            // Recursively open intermediate directories if the document to be
            // opened is not in the immediate file explorer directory.
            let documentPathComponents = document.fileURL.pathComponentsResolvingSymlinksInPath
            if let directoryPathComponents = fileExplorer.directoryURL?.pathComponentsResolvingSymlinksInPath,
                directoryPathComponents.count < documentPathComponents.count - 1 {
                self.fileExplorer(topFileExplorer, open: Document(fileURL: document.fileURL.deletingLastPathComponent()), animated: false)
            }
        
            switch document.resourceType {
                
            case .directory:
                
                let newFileExplorer = FileExplorer(directoryURL: document.fileURL)
                newFileExplorer.delegate = self
                newFileExplorer.parentFileExplorer = fileExplorer
                let editBarButtonItem =
                    UIBarButtonItem(title: FileExplorer.localizedString("edit").capitalized,
                                    style: .plain,
                                    target: self,
                                    action: #selector(didPress(editBarButtonItem:)))
                newFileExplorer.navigationItem.rightBarButtonItem = editBarButtonItem
                newFileExplorer.searchable = true
                
                if let presentationViewController = fileExplorer.delegate?.presentationViewController?(forFileExplorer: fileExplorer) {
                    presentationViewController.show(newFileExplorer, sender: self)
                } else {
                    navigationController?.pushViewController(newFileExplorer, animated: animated)
                }
                
                break
            
            case .regular:
            
                var documentViewController: UIViewController
            
                print(document.uttype.rawValue)
            
                switch document {
                    
                case _ where document.conforms(to: .Image) && !document.conforms(to: .GIF):
                    documentViewController = ImageDocumentViewController(document: document)
                    break
                    
                case _ where document.conforms(to: .Text):
                    documentViewController = TextDocumentViewController(document: document)
                    break
                    
                default:
                    documentViewController = WebDocumentViewController(document: document)
                    break
                    
                }
                
                documentViewController.title = document.displayName
            
                navigationController?.pushViewController(documentViewController, animated: true)
                break
            
            default:
                break
            
            }
        
        }
        
        completionHandler?(true)
        
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, close document: Document, completionHandler: ((Bool) -> ())?) {
        
    }
    
    func fileExplorer(_ fileExplorer: FileExplorer, didPress barButtonItem: UIBarButtonItem, in cell: FileExplorerTableViewCell, from tableView: UITableView, with document: Document) {
        
        let form = STFUForm()
        
        form.add(field: STFUFormField(name: "fileName", type: .text, title: "File Name"))
        
        let formViewController = STFUFormViewController(form: form)
        formViewController.delegate = self
        formViewController.present(in: UIApplication.shared.keyWindow?.rootViewController)
        
        
        
    }
    
}

extension ViewController: DocumentViewControllerDelegate {
    
    open func documentViewController(_ documentViewController: DocumentViewController, didFinishWith document: Document?) {
        for fileURL in topFileExplorer.fileURLs {
            if fileURL == document?.fileURL {
                topFileExplorer.makeDocumentVisible(document)
            }
        }
    }
    
}

extension ViewController: STFUFormDataSource {
    
    open func form(_ form: STFUForm, optionMapFor optionMapKey: String) -> [String : Any] {
        return [:]
    }
    
    open func formCanSubmit(_ form: STFUForm) -> Bool {
        guard
            let fileType = form.value(ofFieldNamed: "fileType") as? URLFileResourceType,
            let fileName = form.value(ofFieldNamed: "fileName") as? String,
            fileName.length > 0,
            let fileURL = self.topFileExplorer.directoryURL?.appendingPathComponent(fileName),
            !fileURL.fileExists
            else { return false }
        if fileType == .symbolicLink {
            guard
                let fileTarget = form.value(ofFieldNamed: "fileTarget") as? String,
                fileTarget.length > 0
                else { return false }
            let destinationURL = fileURL.deletingLastPathComponent() +/ fileTarget
            if !destinationURL.fileExists { return false }
        }
        return true
    }
    
}

extension ViewController: STFUFormViewControllerDelegate {
    
    open func formViewController(_ formViewController: STFUFormViewController, didChange form: STFUForm) {
        print(form.data)
    }
    
    open func formViewController(_ formViewController: STFUFormViewController, didSubmit form: STFUForm) {
        
        guard
            let fileType = form.value(ofFieldNamed: "fileType") as? URLFileResourceType,
            let fileName = form.value(ofFieldNamed: "fileName") as? String,
            fileName.length > 0,
            let fileURL = self.topFileExplorer.directoryURL?.appendingPathComponent(fileName)
            else { return }
        
        let document = Document(fileURL: fileURL)
        document.resourceType = fileType
        
        if fileType == .symbolicLink {
            guard
                let fileTarget = form.value(ofFieldNamed: "fileTarget") as? String,
                fileTarget.length > 0
                else { return }
            let destinationURL = URL(fileURLWithPath: fileTarget)
            document.symbolicDestinationURL = destinationURL
        }
        
        document.open() { (success) in
            document.save() { (success) in
                formViewController.dismiss(animated: true) {
                    guard success else { return }
                    self.topFileExplorer.loadFromDirectoryURL()
                    guard document.isRegularFile else { return }
                    self.open(document)
                }
            }
        }
            
    }
    
}

// MARK: - Event Handler Methods
extension ViewController {
    
    @objc
    open func didPress(editBarButtonItem: UIBarButtonItem) {
        topFileExplorer.setEditing(!topFileExplorer.isEditing, animated: true)
        editBarButtonItem.title = !topFileExplorer.isEditing ? FileExplorer.localizedString("edit").capitalized : FileExplorer.localizedString("done").capitalized
    }
    
    @objc
    open func didPress(deleteBarButtonItem: UIBarButtonItem) {
        topFileExplorer.removeDocuments()
    }
    
    @objc
    open func didPress(cutBarButtonItem: UIBarButtonItem) {
        clipboardAction = .move
        clipboardDocuments = topFileExplorer.selectedDocuments
        topFileExplorer.updateToolbarItems()
    }
    
    @objc
    open func didPress(copyBarButtonItem: UIBarButtonItem) {
        clipboardAction = .copy
        clipboardDocuments = topFileExplorer.selectedDocuments
        topFileExplorer.updateToolbarItems()
    }
    
    @objc
    open func didPress(pasteBarButtonItem: UIBarButtonItem) {
        guard let destinationURL = topFileExplorer.directoryURL else { return }
        switch clipboardAction {
        case .copy:
            fileExplorer(topFileExplorer, copy: clipboardDocuments, to: destinationURL, completionHandler: nil)
            break
        case .move:
            fileExplorer(topFileExplorer, move: clipboardDocuments, to: destinationURL, completionHandler: nil)
            break
        default:
            break
        }
        clipboardAction = .none
        clipboardDocuments = []
        topFileExplorer.loadFromDirectoryURL()
        topFileExplorer.updateToolbarItems()
    }
    
    @objc
    open func didPress(zipBarButtonItem: UIBarButtonItem) {
        
    }
    
    @objc
    open func didPress(addBarButtonItem: UIBarButtonItem) {
        
        let form = STFUForm()
        form.dataSource = self
        
        let fileTypeRegularField =
            STFUFormField(id: "fileTypeRegular", name: "fileType",
                          type: .radio, title: "File",
                          with: [.checked: true,
                                 .value: URLFileResourceType.regular,])
        form.add(field: fileTypeRegularField)
        
        let fileTypeDirectoryField =
            STFUFormField(id: "fileTypeDirectory", name: "fileType",
                          type: .radio, title: "Folder",
                          with: [.value: URLFileResourceType.directory,])
        form.add(field: fileTypeDirectoryField)
        
        let fileTypeSymbolicLinkField =
            STFUFormField(id: "fileTypeSymbolicLink", name: "fileType",
                          type: .radio, title: "Symbolic Link",
                          with: [.value: URLFileResourceType.symbolicLink,])
        form.add(field: fileTypeSymbolicLinkField)
        
        let fileNameField =
            STFUFormField(name: "fileName", type: .text,
                          title: "File Name",
                          with: [.placeholder: "File Name (i.e. myfile.html)",])
        form.add(field: fileNameField)
        
        let fileTargetField =
            STFUFormField(name: "fileTarget", type: .text,
                          title: "Link Target",
                          with: [.placeholder: "Link target relative to current directory.",
                                 .dependencies: [STFUFormField(name: "fileType", with: [.value: URLFileResourceType.symbolicLink])],
                                 .hideWhenDisabled: true,])
        form.add(field: fileTargetField)
        
        form.add(section: .init(header: "File Type",
                                fields: [fileTypeRegularField,
                                         fileTypeDirectoryField,
                                         fileTypeSymbolicLinkField,
                                         ]))
        
        form.add(section: .init(header: "File Name",
                                fields: [
                                    fileNameField,
                                    fileTargetField,
                                    ]))
        
        let formViewController = STFUFormViewController(form: form)
        formViewController.delegate = self
        formViewController.present(in: UIApplication.shared.keyWindow?.rootViewController)
        
    }
    
    @objc
    open func didPress(settingsBarButtonItem: UIBarButtonItem) {
        
        let form = STFUForm()
        
        let formViewController = STFUFormViewController(form: form)
        formViewController.delegate = self
        
        formViewController.present(in: UIApplication.shared.keyWindow?.rootViewController)
        
    }
    
}
