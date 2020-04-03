//
//  SnapToLiveButton.swift
//  LiveLikeSDK
//
//  Created by Cory Sullivan on 2019-03-20.
//

import UIKit

class SnapToLiveButton: UIButton {
    private var theme: Theme?

    public func setTheme(_ theme: Theme) {
        self.theme = theme
        setNeedsDisplay() // forces redraw
    }

    override func draw(_ rect: CGRect) {
        if let theme = theme {
            drawSnapToLiveIcon(frame: rect, bgColor: theme.chatDetailPrimaryColor, arrowColor: theme.chatDetailSecondaryColor)
        } else {
            drawSnapToLiveIcon(frame: rect,
                               bgColor: UIColor(red: 0.137, green: 0.157, blue: 0.176, alpha: 1.000),
                               arrowColor: UIColor(red: 0.800, green: 0.320, blue: 0.320, alpha: 1.000))
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 30, height: 30)
    }

    func drawSnapToLiveIcon(frame: CGRect = CGRect(x: 0, y: 0, width: 30, height: 30), bgColor: UIColor, arrowColor: UIColor) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!

        //// circle Drawing
        let circlePath = UIBezierPath(ovalIn: CGRect(x: frame.minX, y: frame.minY, width: 30, height: 30))
        context.saveGState()
        bgColor.setFill()
        circlePath.fill()
        context.restoreGState()

        //// arrowDown Drawing
        let arrowDownPath = UIBezierPath()
        arrowDownPath.move(to: CGPoint(x: frame.minX + 15.03, y: frame.minY + 21))
        arrowDownPath.addCurve(to: CGPoint(x: frame.minX + 14.23, y: frame.minY + 20.66), controlPoint1: CGPoint(x: frame.minX + 14.74, y: frame.minY + 21), controlPoint2: CGPoint(x: frame.minX + 14.45, y: frame.minY + 20.89))
        arrowDownPath.addLine(to: CGPoint(x: frame.minX + 7.27, y: frame.minY + 13.45))
        arrowDownPath.addCurve(to: CGPoint(x: frame.minX + 7.97, y: frame.minY + 11.49), controlPoint1: CGPoint(x: frame.minX + 6.83, y: frame.minY + 12.99), controlPoint2: CGPoint(x: frame.minX + 6.83, y: frame.minY + 12.28))
        arrowDownPath.addCurve(to: CGPoint(x: frame.minX + 9.98, y: frame.minY + 11.49), controlPoint1: CGPoint(x: frame.minX + 9.12, y: frame.minY + 10.69), controlPoint2: CGPoint(x: frame.minX + 9.53, y: frame.minY + 11.03))
        arrowDownPath.addLine(to: CGPoint(x: frame.minX + 15.03, y: frame.minY + 16.74))
        arrowDownPath.addLine(to: CGPoint(x: frame.minX + 20.09, y: frame.minY + 11.49))
        arrowDownPath.addCurve(to: CGPoint(x: frame.minX + 22.05, y: frame.minY + 11.49), controlPoint1: CGPoint(x: frame.minX + 20.53, y: frame.minY + 11.03), controlPoint2: CGPoint(x: frame.minX + 21.14, y: frame.minY + 10.67))
        arrowDownPath.addCurve(to: CGPoint(x: frame.minX + 22.79, y: frame.minY + 13.45), controlPoint1: CGPoint(x: frame.minX + 22.97, y: frame.minY + 12.3), controlPoint2: CGPoint(x: frame.minX + 23.23, y: frame.minY + 12.99))
        arrowDownPath.addLine(to: CGPoint(x: frame.minX + 15.83, y: frame.minY + 20.66))
        arrowDownPath.addCurve(to: CGPoint(x: frame.minX + 15.03, y: frame.minY + 21), controlPoint1: CGPoint(x: frame.minX + 15.61, y: frame.minY + 20.89), controlPoint2: CGPoint(x: frame.minX + 15.32, y: frame.minY + 21))
        arrowDownPath.close()
        arrowDownPath.usesEvenOddFillRule = true
        arrowColor.setFill()
        arrowDownPath.fill()
    }
}
