//
//  ProjectFolderView.swift
//  DrakkenEngine
//
//  Created by Allison Lindner on 18/10/16.
//  Copyright © 2016 Drakken Studio. All rights reserved.
//

import Cocoa

public let SCRIPT_PASTEBOARD_TYPE = "drakkenengine.projectfolder.item.script"
public let IMAGE_PASTEBOARD_TYPE = "drakkenengine.projectfolder.item.image"
public let SPRITEDEF_PASTEBOARD_TYPE = "drakkenengine.projectfolder.item.spritedef"

internal class FolderItem: NSObject {
    var icon: NSImage
    var name: String
    var url: URL
    var children: [FolderItem]
    
    internal init(icon: NSImage, name: String, url: URL, children: [FolderItem]) {
        self.icon = icon
        self.name = name
        self.url = url
        self.children = children
        
        super.init()
    }
}

fileprivate class RootItem: FolderItem {}

class ProjectFolderView: NSOutlineView, NSOutlineViewDataSource, NSOutlineViewDelegate, NSPasteboardItemDataProvider, NSMenuDelegate {
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    var draggedItem: FolderItem?
    
    private var itens: [RootItem] = [RootItem]()
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
        self.dataSource = self
        self.delegate = self
        
        doubleAction = #selector(self.doubleActionSelector)
        
        self.register(forDraggedTypes: [SCRIPT_PASTEBOARD_TYPE, IMAGE_PASTEBOARD_TYPE])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if self.tableColumns[0].headerCell.controlView != nil {
            if self.tableColumns[0].headerCell.controlView!.frame.width != superview!.frame.width - 3 {
                self.tableColumns[0].headerCell.controlView!.setFrameSize(
                    NSSize(width: superview!.frame.width - 3,
                           height: self.tableColumns[0].headerCell.controlView!.frame.size.height)
                )
                self.tableColumns[0].sizeToFit()
            }
        }
        
        super.draw(dirtyRect)
    }
    
    internal func doubleActionSelector() {
        if let item = self.item(atRow: clickedRow) as? FolderItem {
            let url = item.url
            
            if NSApplication.shared().mainWindow!.contentViewController is EditorViewController {
                let editorVC = NSApplication.shared().mainWindow!.contentViewController as! EditorViewController
                if url.pathExtension == "dkscene" {
                    editorVC.currentSceneURL = url
                    
                    editorVC.editorView.scene.DEBUG_MODE = false
                    editorVC.editorView.scene.load(url: url)
                    editorVC.editorView.Init()
                    editorVC.transformsView.reloadData()
                    
                    editorVC.selectedTransform = nil
                    editorVC.inspectorView.reloadData()
                } else if url.pathExtension == "js" {
                    NSWorkspace.shared().open(url)
                } else if url.isFileURL {
                    if NSImage(contentsOf: url) != nil {
                        NSWorkspace.shared().open(url)
                    }
                }
            }
        }
    }
    
    internal func loadData(for url: URL) {
        let rootItens = getItens(from: url)
        itens.removeAll()
        
        for i in rootItens {
            let rootItem = RootItem(icon: i.icon, name: i.name, url: i.url, children: [FolderItem]())
            itens.append(rootItem)
            
            loadItem(from: i.url, at: rootItem)
        }
        
        self.reloadData()
    }
    
    private func loadItem(from url: URL, at: FolderItem) {
        let contentItens = getItens(from: url)
        
        for i in contentItens {
            let item = FolderItem(icon: i.icon, name: i.name, url: i.url, children: [FolderItem]())
            at.children.append(item)
            
            loadItem(from: i.url, at: item)
        }
    }
    
    internal func getItens(from url: URL) -> [(icon: NSImage, name: String, url: URL)] {
        if !url.hasDirectoryPath {
            return []
        }
        
        let fileManager = FileManager()
        var contentItens = [(icon: NSImage, name: String, url: URL)]()
        
        let enumerator = fileManager.enumerator(at: url,
                                                includingPropertiesForKeys: [URLResourceKey.effectiveIconKey,URLResourceKey.localizedNameKey],
                                                options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
                                                        .union(FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants)
                                                        .union(FileManager.DirectoryEnumerationOptions.skipsPackageDescendants),
                                                errorHandler: { (u, error) -> Bool in
                                                    NSLog("URL: \(u.path) - Error: \(error)")
                                                    return false
        })
        
        while let u = enumerator?.nextObject() as? URL {
            do{
                
                let properties = try u.resourceValues(forKeys: [URLResourceKey.effectiveIconKey,URLResourceKey.localizedNameKey]).allValues
                
                let icon = properties[URLResourceKey.effectiveIconKey] as? NSImage ?? NSImage()
                let name = properties[URLResourceKey.localizedNameKey] as? String ?? " "
                
                contentItens.append((icon: icon, name: name, url: u))
            }
            catch {
                NSLog("Error reading file attributes")
            }
        }
        
        return contentItens
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item != nil {
            if let i = item as? FolderItem {
                return i.children.count
            }
        }
        
        return itens.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item != nil {
            if let i = item as? FolderItem {
                return i.children[index]
            }
        }
        
        return itens[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let i = item as? FolderItem {
            return i.children.count > 0
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var image:NSImage?
        var text:String = ""
        var cellIdentifier: String = ""
        
        if let i = item as? FolderItem {
            if tableColumn == outlineView.tableColumns[0] {
                image = i.icon
                text = i.name
                cellIdentifier = "FolderItemID"
            }
            
            if let cell = outlineView.make(withIdentifier: cellIdentifier, owner: nil) as? PFolderItemCell {
                cell.textField?.stringValue = text
                cell.imageView?.image = image ?? nil
                
                cell.folderItem = i
                
                return cell
            }
        }
        
        return nil
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let item = item(atRow: selectedRow) as? FolderItem {
            if item.url.pathExtension == "dksprite" {
                appDelegate.editorViewController?.selectedSpriteDef = item.url
                appDelegate.editorViewController?.selectedTransform = nil
                
                appDelegate.editorViewController?.transformsView.deselectAll(nil)
                
                appDelegate.editorViewController?.inspectorView.reloadData()
            } else {
                if appDelegate.editorViewController?.selectedSpriteDef != nil {
                    appDelegate.editorViewController?.selectedSpriteDef = nil
                    appDelegate.editorViewController?.inspectorView.reloadData()
                }
            }
        } else {
            if appDelegate.editorViewController?.selectedSpriteDef != nil {
                appDelegate.editorViewController?.selectedSpriteDef = nil
                appDelegate.editorViewController?.inspectorView.reloadData()
            }
        }
        
        if selectedRow >= 0 {
            if let cell = self.view(atColumn: selectedColumn, row: selectedRow, makeIfNecessary: false) as? PFolderItemCell {
                appDelegate.editorViewController?.selectedFolderItem = cell.folderItem
            }
        } else {
            appDelegate.editorViewController?.selectedFolderItem = nil
        }
    }
    
    //MARK: Drag and Drop Setup
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        draggedItem = item as? FolderItem
        var pbItem: NSPasteboardItem? = nil
        
        if draggedItem!.url.pathExtension == "js" {
            pbItem = NSPasteboardItem()
            pbItem!.setDataProvider(self, forTypes: [SCRIPT_PASTEBOARD_TYPE])
        } else if NSImage(contentsOf: draggedItem!.url) != nil {
            pbItem = NSPasteboardItem()
            pbItem!.setDataProvider(self, forTypes: [IMAGE_PASTEBOARD_TYPE])
        } else if draggedItem!.url.pathExtension == "dksprite" {
            pbItem = NSPasteboardItem()
            pbItem!.setDataProvider(self, forTypes: [SPRITEDEF_PASTEBOARD_TYPE])
        }
        
        return pbItem
    }
    
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        
        draggedItem = draggedItems[0] as? FolderItem
        
        if draggedItem!.url.pathExtension == "js" {
            appDelegate.editorViewController?.draggedScript = draggedItem!.url.deletingPathExtension().lastPathComponent
            session.draggingPasteboard.setString(draggedItem!.url.deletingPathExtension().lastPathComponent,
                                                 forType: SCRIPT_PASTEBOARD_TYPE)
        } else if NSImage(contentsOf: draggedItem!.url) != nil {
            _ = dTexture(draggedItem!.url.lastPathComponent)
            let spriteDef = dSpriteDef(draggedItem!.url.lastPathComponent, texture: draggedItem!.url.lastPathComponent)
            DrakkenEngine.Register(sprite: spriteDef)
            DrakkenEngine.Setup()
            
            appDelegate.editorViewController?.draggedImage = draggedItem!.url.lastPathComponent
            session.draggingPasteboard.setString(draggedItem!.url.lastPathComponent,
                                                 forType: IMAGE_PASTEBOARD_TYPE)
        } else if draggedItem!.url.pathExtension == "dksprite" {
            appDelegate.editorViewController?.draggedSpriteDef = dSpriteDef(json: draggedItem!.url)
            session.draggingPasteboard.setString(draggedItem!.url.lastPathComponent,
                                                 forType: SPRITEDEF_PASTEBOARD_TYPE)
        }
    }
    
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: String) {
        if draggedItem!.url.pathExtension == "js" {
            item.setString(draggedItem!.url.deletingPathExtension().lastPathComponent, forType: SCRIPT_PASTEBOARD_TYPE)
        } else if NSImage(contentsOf: draggedItem!.url) != nil {
            item.setString(draggedItem!.url.lastPathComponent, forType: IMAGE_PASTEBOARD_TYPE)
        } else if draggedItem!.url.pathExtension == "dksprite" {
            item.setString(draggedItem!.url.lastPathComponent, forType: SPRITEDEF_PASTEBOARD_TYPE)
        }
    }
    
    //Mark: Menu
    
    override func menu(for event: NSEvent) -> NSMenu? {
        if becomeFirstResponder() {
            let point = NSApplication.shared().mainWindow!.contentView!.convert(event.locationInWindow, to: self)
            let column = self.column(at: point)
            let row = self.row(at: point)
            
            if column >= 0 && row >= 0 {
                if let cell = self.view(atColumn: column, row: row, makeIfNecessary: false) as? PFolderItemCell {
                    if NSImage(contentsOf: cell.folderItem.url) != nil {
                        NSLog("\(cell.folderItem.name)")
                        
                        if self.selectedRow != row {
                            self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                        }
                        
                        if let menu = cell.menu as? ImageMenu {
                            menu.selectedFolderItem = cell.folderItem
                            return menu
                        }
                        return nil
                    }
                }
            }
        }
        
        return nil
    }
}
