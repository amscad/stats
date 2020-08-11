//
//  Chart.swift
//  StatsKit
//
//  Created by Serhiy Mytrovtsiy on 17/04/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

public enum chart_t: Int {
    case line = 0
    case bar = 1
    
    init?(value: Int) {
        self.init(rawValue: value)
    }
}

public struct circle_segment {
    let value: Double
    let color: NSColor
    
    public init(value: Double, color: NSColor) {
        self.value = value
        self.color = color
    }
}

public class LineChartView: NSView {
    public var points: [Double]? = nil
    public var transparent: Bool = true
    
    public var color: NSColor = NSColor.controlAccentColor
    
    public init(frame: NSRect, num: Int) {
        self.points = Array(repeating: 0, count: num)
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if self.points?.count == 0 {
            return
        }
        
        let lineColor: NSColor = self.color
        var gradientColor: NSColor = self.color.withAlphaComponent(0.5)
        if !self.transparent {
            gradientColor = self.color.withAlphaComponent(0.8)
        }
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setShouldAntialias(true)
        let height: CGFloat = self.frame.size.height - self.frame.origin.y - 0.5
        let xRatio: CGFloat = self.frame.size.width / CGFloat(self.points!.count)
        
        let columnXPoint = { (point: Int) -> CGFloat in
            return (CGFloat(point) * xRatio) + dirtyRect.origin.x
        }
        let columnYPoint = { (point: Int) -> CGFloat in
            return CGFloat((CGFloat(truncating: self.points![point] as NSNumber) * height)) + dirtyRect.origin.y + 0.5
        }
        
        let linePath = NSBezierPath()
        let x: CGFloat = columnXPoint(0)
        let y: CGFloat = columnYPoint(0)
        linePath.move(to: CGPoint(x: x, y: y))
        
        for i in 1..<self.points!.count {
            linePath.line(to: CGPoint(x: columnXPoint(i), y: columnYPoint(i)))
        }
        
        lineColor.setStroke()
        
        context.saveGState()
        
        let underLinePath = linePath.copy() as! NSBezierPath
        
        underLinePath.line(to: CGPoint(x: columnXPoint(self.points!.count - 1), y: 0))
        underLinePath.line(to: CGPoint(x: columnXPoint(0), y: 0))
        underLinePath.close()
        underLinePath.addClip()
        
        gradientColor.setFill()
        let rectPath = NSBezierPath(rect: dirtyRect)
        rectPath.fill()
        
        context.restoreGState()
        
        linePath.stroke()
        linePath.lineWidth = 0.5
    }
    
    public func addValue(_ value: Double) {
        self.points!.remove(at: 0)
        self.points!.append(value)
        if self.window?.isVisible ?? true {
            self.display()
        }
    }
}

public class CircleGraphView: NSView {
    private var value: Double? = nil
    private var segments: [circle_segment] = []
    
    public init(frame: NSRect, segments: [circle_segment]) {
        self.segments = segments
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let arcWidth: CGFloat = 7.0
        let fullCircle = 2 * CGFloat.pi
        var segments = self.segments
        let totalAmount = segments.reduce(0) { $0 + $1.value }
        if totalAmount < 1 {
            segments.append(circle_segment(value: Double(1-totalAmount), color: NSColor.lightGray.withAlphaComponent(0.5)))
        }
        
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (min(rect.width, rect.height) - arcWidth) / 2
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setShouldAntialias(true)
        
        context.setLineWidth(arcWidth)
        context.setLineCap(.butt)
        
        let startAngle: CGFloat = CGFloat.pi/2
        var previousAngle = startAngle
        
        for segment in segments.reversed() {
            let currentAngle: CGFloat = previousAngle + (CGFloat(segment.value) * fullCircle)
            
            context.setStrokeColor(segment.color.cgColor)
            context.addArc(center: centerPoint, radius: radius, startAngle: previousAngle, endAngle: currentAngle, clockwise: false)
            context.strokePath()
            
            previousAngle = currentAngle
        }
        
        if let value = self.value {
            let stringAttributes = [
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 15, weight: .regular),
                NSAttributedString.Key.foregroundColor: isDarkMode ? NSColor.white : NSColor.textColor,
                NSAttributedString.Key.paragraphStyle: NSMutableParagraphStyle()
            ]
            
            let percentage = "\(Int(value*100))%"
            let width: CGFloat = percentage.widthOfString(usingFont: NSFont.systemFont(ofSize: 15))
            let rect = CGRect(x: (self.frame.width-width)/2, y: (self.frame.height-12)/2, width: width, height: 12)
            
            let str = NSAttributedString.init(string: percentage, attributes: stringAttributes)
            str.draw(with: rect)
        }
    }
    
    public func setValue(_ value: Double) {
        self.value = value
        if self.window?.isVisible ?? true {
            self.display()
        }
    }
    
    public func setSegments(_ segments: [circle_segment]) {
        self.segments = segments
        if self.window?.isVisible ?? true {
            self.display()
        }
    }
}
