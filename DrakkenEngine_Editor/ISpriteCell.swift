//
//  ISpriteCell.swift
//  DrakkenEngine
//
//  Created by Allison Lindner on 24/10/16.
//  Copyright © 2016 Drakken Studio. All rights reserved.
//

import Cocoa

class ISpriteCell: NSTableCellView, NSTextFieldDelegate {

    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var spriteNameTF: NSTextField!
    @IBOutlet weak var frameTF: NSTextField!
    
    @IBOutlet weak var wsTF: NSTextField!
    @IBOutlet weak var hsTF: NSTextField!
    
    internal var sprite: dSprite!
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
        self.wsTF.delegate = self
        self.hsTF.delegate = self
        self.frameTF.delegate = self
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let fieldEditor = obj.object as! NSTextField
        
        if fieldEditor.identifier == "scaleWID" {
            let w = fieldEditor.floatValue
            sprite.meshRender.scale.Set(w, sprite.meshRender.scale.height)
            appDelegate.editorViewController?.editorView.Reload()
        } else if fieldEditor.identifier == "scaleHID" {
            let h = fieldEditor.floatValue
            sprite.meshRender.scale.Set(sprite.meshRender.scale.width, h)
            appDelegate.editorViewController?.editorView.Reload()
        } else if fieldEditor.identifier == "frameID" {
            let frame = fieldEditor.intValue
            sprite.set(frame: frame)
            
            appDelegate.editorViewController!.editorView.Reload()
        }
    }
    
    @IBAction func removeComponent(_ sender: Any) {
        sprite.removeFromParent()
        sprite.meshRender.removeFromParent()
        appDelegate.editorViewController?.inspectorView.reloadData()
        appDelegate.editorViewController!.editorView.Reload()
    }
}
