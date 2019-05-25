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

import SwiftyFileSystem

/// Specifies the required event handler methods for an object that
/// will delegate one or more `FileExplorer` instances.
@objc
public protocol FileExplorerDelegate: class  {
    
    // MARK: - Configuration Methods
    
    /// Returns a set of toolbar items to display for a file explorer.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide with toolbar items.
    @objc optional
    func toolbarItems(forFileExplorer fileExplorer: FileExplorer) -> [UIBarButtonItem]
    
    /// Returns the status text to display for a file explorer.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide status text for.
    @objc optional
    func statusText(forFileExplorer fileExplorer: FileExplorer) -> String?
    
    /// Specifies the edit actions that should display for an item in the table
    /// view of a file explorer for a specific index path.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide edit actions.
    ///     - indexPath: of the cell to provide edit actions.
    ///     - tableView: of `fileExplorer`.
    ///     - document: associated with represented at `indexPath`.
    /// - Returns: edit actions that should display for an item when the user
    /// slides left inside of the table view cell in `tableView` and located
    /// at `indexPath`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, editActionsForRowAt indexPath: IndexPath, tableView: UITableView, document: Document) -> [UITableViewRowAction]
    
    /// Specifies the advanced actions that should display for an item in the
    /// table view of a file explorer for a specific index path.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide advanced actions.
    ///     - indexPath: of the cell to provide advanced actions.
    ///     - tableView: of `fileExplorer`.
    ///     - document: associated with represented at `indexPath`.
    ///     - presentingViewController: that will display the alert actions.
    /// - Returns: advanced actions that should display for an item when the
    /// user presses and holds inside of a table view cell in `tableView` and
    /// located at `indexPath`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, longPressActionsForRowAt indexPath: IndexPath, tableView: UITableView, document: Document, presentingViewController: UIViewController) -> [UIAlertAction]
    
    /// Returns a unique section key for a given file explorer and document.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide a section titles.
    ///     - document: to provide a section title for.
    /// - Returns: a unique key for the specified file explorer and document.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, sectionKeyFor document: Document) -> String?
    
    /// Returns a section title for a given file explorer and document.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide a section titles.
    ///     - document: to provide a section title for.
    /// - Returns: a title for the specified file explorer and document.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, sectionTitleFor document: Document) -> String?
    
    /// Returns a section index title for a given file explorer and document.
    ///
    /// - Parameters:
    ///     - fileExplorer: to provide a section index titles.
    ///     - document: to provide a section index title for.
    /// - Returns: an index title for the specified file explorer and document.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, sectionIndexTitleFor document: Document) -> String?
    
    // MARK: - Table View Touch Event Handler Methods
    
    /// Called when the user selects a single table view cell.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - indexPath: of the row was selected.
    ///     - tableView: of `fileExplorer`.
    ///     - document: associated with `cell` in `tableView`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, didSelectRowAt indexPath: IndexPath,
                               tableView: UITableView, document: Document)
    
    /// Called when the user deselects a single table view cell.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - indexPath: of the row was deselected.
    ///     - tableView: of `fileExplorer`.
    ///     - document: associated with `cell` in `tableView`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, didDeselectRowAt indexPath: IndexPath,
                               tableView: UITableView, document: Document)
    
    /// Called when the user double taps a single table view cell.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - indexPath: of the row was double tapped.
    ///     - tableView: of `fileExplorer`.
    ///     - document: associated with `cell` in `tableView`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, didDoubleTapRowAt indexPath: IndexPath,
                               tableView: UITableView, document: Document)
    
    /// Called when the user presses and holds a table view cell.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - indexPath: of the row was the pressed and held.
    ///     - tableView: of `fileExplorer`.
    ///     - document: associated with `cell` in `tableView`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, didPressAndHoldRowAt indexPath: IndexPath,
                               tableView: UITableView, document: Document)
    
    /// Called when the accessory button of a table view cell is tapped
    /// by the user.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - indexPath: of the row whose accessory bar button item was selected.
    ///     - tableView: of `fileExplorer`.
    ///     - barButtonItem: that was pressed.
    ///     - document: associated with `cell` in `tableView`.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, didSelectRowAt indexPath: IndexPath,
                               tableView: UITableView, barButtonItem: UIBarButtonItem?, document: Document)
    
    // MARK: - Event Handler Methods
    
    /// Called before a file explorer has loaded its file system.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    @objc optional
    func fileExplorerWillLoadFileSystem(_ fileExplorer: FileExplorer)
    
    /// Called after a file explorer has loaded its file system.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    @objc optional
    func fileExplorerDidLoadFileSystem(_ fileExplorer: FileExplorer)
    
    /// Called before a file explorer view has appeared.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - animated: `true` if the transition is animated.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, viewWillAppear animated: Bool)
    
    /// Called after a file explorer view has appeared.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - animated: `true` if the transition is animated.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, viewDidAppear animated: Bool)
    
    /// Called before a file explorer view has disappeared.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    @objc optional
    func fileExplorerViewWillDisappear(_ fileExplorer: FileExplorer)
    
    /// Called after a file explorer view has disappeared.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    @objc optional
    func fileExplorerViewDidDisappear(_ fileExplorer: FileExplorer)
    
    /// Called when the user changes the editing mode of a file explorer instance.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - animated: `true` if the transition is animated.
    @objc optional
    func fileExplorer(_ fileExplorer: FileExplorer, didChangeEditingMode animated: Bool)
    
    // MARK: - Document Handler Methods
    
    /// Called when the user attempts to create a document.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - document: the user is attempting to create.
    ///     - completionHandler: to execute after the delegate has
    /// completed the task.
    func fileExplorer(_ fileExplorer: FileExplorer, create document: Document, completionHandler: ((Bool) -> ())?)
    
    /// Called when the user attempts to delete documents.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - documents: the user is attempting to delete.
    ///     - completionHandler: to execute after the delegate has
    /// completed the task.
    func fileExplorer(_ fileExplorer: FileExplorer, remove documents: [Document], completionHandler: ((Bool) -> ())?)
    
    /// Called when the user attempts to move documents.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - documents: the user is attempting to move.
    ///     - destinationURL: to move the documents to.
    ///     - completionHandler: to execute after the delegate has
    /// completed the task.
    func fileExplorer(_ fileExplorer: FileExplorer, move documents: [Document], to destinationURL: URL, completionHandler: ((Bool) -> ())?)
    
    /// Called when the user attempts to copy documents.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - documents: the user is attempting to copy.
    ///     - destinationURL: to copy the documents to.
    ///     - completionHandler: to execute after the delegate has
    /// completed the task.
    func fileExplorer(_ fileExplorer: FileExplorer, copy documents: [Document], to destinationURL: URL, completionHandler: ((Bool) -> ())?)
    
    /// Called when the user attempts to open a document.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - document: the user is attempting to open.
    ///     - completionHandler: to execute after the delegate has
    /// completed the task.
    func fileExplorer(_ fileExplorer: FileExplorer, open document: Document, completionHandler: ((Bool) -> ())?)
    
    /// Called when the user attempts to close a document.
    ///
    /// - Parameters:
    ///     - fileExplorer: that spawned this event.
    ///     - document: the user is attempting to close.
    ///     - completionHandler: to execute after the delegate has
    /// completed the task.
    func fileExplorer(_ fileExplorer: FileExplorer, close document: Document, completionHandler: ((Bool) -> ())?)
    
}
