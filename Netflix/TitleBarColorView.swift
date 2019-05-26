//
//  TitleColorView.swift
//  Netflix
//
//  Created by Jakob Sudau on 26.05.19.
//  Copyright © 2019 Daniel Farrelly. All rights reserved.
//

import Cocoa

class TitleColorView: NSView {
    // draw is simple; just fill the rect with red
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.set()
        dirtyRect.fill()
    }
    
    // provide an intrinsic content size, to make our view prefer to be the same height
    // as the title bar.
    override var intrinsicContentSize: NSSize {
        guard let window = self.window, let contentView = window.contentView else {
            return super.intrinsicContentSize
        }
        
        // contentView.frame is the entire frame, contentLayoutRect is the part not
        // overlapping the title bar. The difference will therefore be the height
        // of the title bar.
        let height = NSHeight(contentView.frame) - NSHeight(window.contentLayoutRect)
        
        // I just return noIntrinsicMetric for the width since the edge constraints we set
        // up in IB will override whatever we put here anyway
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }
}
