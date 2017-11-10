//
//  GraphingView.swift
//  Calculator
//
//  Created by William on 2017/10/2.
//  Copyright © 2017年 Stanford. All rights reserved.
//

import UIKit


// data source protocol, for getting x, y value to draw from the function in brain
protocol GraphViewDataSource: class {
    func y(x : CGFloat) -> CGFloat?
}




@IBDesignable
class GraphingView: UIView {

    // screen's scale
    @IBInspectable
    var scale: CGFloat = 1.0 { didSet{ setNeedsDisplay() } }
    
    // set the linewidth
    @IBInspectable
    var lineWidth: CGFloat = 2.0 { didSet{ setNeedsDisplay() } }
    
//    // set the graph origin
//    var origin: CGPoint = CGPoint() {
//        didSet {
//            isResetOriginPoint = false
//            setNeedsDisplay()
//        }
//    }
//
//    // reset origin helper bool
//    var isResetOriginPoint: Bool = true {             // origin method 1       (tutorial)
//        didSet {
//            if isResetOriginPoint {
//                setNeedsDisplay()
//            }
//        }
//    }
    
//    var origin: CGPoint {
//        get {
//            if isUserSetOrigin {
//                return originPointSetByUser!          // origin method 2      (my way)
//            } else {
//                return self.center
//            }
//        }
//        set {
//            originPointSetByUser = newValue
//            isUserSetOrigin = true
//            setNeedsDisplay()
//        }
//    }
//
//    var isUserSetOrigin = false
//
//    var originPointSetByUser: CGPoint?
    
    var count = 0   // for performance testing use  (my way)
    // origin method 3, tutorial way, it make origin refer to the center point even in different bounds
    var origin: CGPoint {
        get {
            var origin = originRelativeToCenter
            if geometryIsReady {
                origin.x += center.x
                origin.y += center.y
            }
            // if you changed origin to computed property, the best way to reduce the load of this computed property
            // is to pass it as argument to drawGraph(origin) method, or set local variable to that method
            // if it has no argument like drawGraph(), because of drawing method have to loop and get this property.
            count += 1   // test use
            //--------// (my way)
            return origin
        }
        set {
            var origin = newValue
            if geometryIsReady {
                origin.x -= center.x
                origin.y -= center.y
            }
            originRelativeToCenter = origin
        }
    }
    var originRelativeToCenter: CGPoint = CGPoint() { didSet{ setNeedsDisplay() } }
    var geometryIsReady: Bool = false
    
    // data source: function for drawing
    var graphDataSource: GraphViewDataSource?
    
    
    
    // Private properties
    
    // this property is equate to scale property
    private var pointsPerUnits: CGFloat {
        return 40 * scale
    }
    // Coordinate Axes drawer
    private var axesDrawer = AxesDrawer()
    
    // main method of this view
    override func draw(_ rect: CGRect) {
//        if isResetOriginPoint {
//            origin = center                       origin method 1     (tutorial)
//        }
        if !geometryIsReady && originRelativeToCenter != CGPoint.zero {
            let originHelper = origin
            geometryIsReady = true
            origin = originHelper
        }
        axesDrawer.contentScaleFactor = self.contentScaleFactor
        axesDrawer.drawAxes(in: bounds, origin: origin , pointsPerUnit: pointsPerUnits)
        drawGraph(origin: origin)
    }
    
    
    
    // heart of graph view
    private func drawGraph(origin: CGPoint) {   // due to origin is computed property, be an argument improving performance
        var isFirstaPoint = true
        var point = CGPoint()
        let path = UIBezierPath()
        
        for i in 0..<Int(bounds.size.width * self.contentScaleFactor) {
            point.x = CGFloat(i) / self.contentScaleFactor
            if let y = graphDataSource?.y(x: (point.x - origin.x) / pointsPerUnits) {
                if !y.isNormal && !y.isZero {
                    isFirstaPoint = true
                    continue
                }
                point.y = origin.y - (y * pointsPerUnits)
                if isFirstaPoint {
                    path.move(to: point)
                    isFirstaPoint = false
                } else {
                    path.addLine(to: point)
                }
            } else {
                isFirstaPoint = true
            }
        }
        path.lineWidth = lineWidth
        UIColor.orange.setStroke()
        path.stroke()
        print(count)
    }
    
    var snapShot: UIView?
    
    // Pinch gesture delegate method
    
    @objc func zoomingTheScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer)
    {
        switch pinchRecognizer.state {                                 // improved method for zooming (tutorial)
        case .began:
            snapShot = self.snapshotView(afterScreenUpdates: false)
            snapShot!.alpha = 0.8
            self.addSubview(snapShot!)
        case .changed:
            let touchPoint = pinchRecognizer.location(in: self)
            snapShot!.frame.size.width *= pinchRecognizer.scale
            snapShot!.frame.size.height *= pinchRecognizer.scale
            snapShot!.frame.origin.x = snapShot!.frame.origin.x * pinchRecognizer.scale + (1 - pinchRecognizer.scale) * touchPoint.x
            snapShot!.frame.origin.y = snapShot!.frame.origin.y * pinchRecognizer.scale + (1 - pinchRecognizer.scale) * touchPoint.y
            pinchRecognizer.scale = 1.0
        case .ended:
            let changeScale = snapShot!.frame.width / self.frame.width
            scale *= changeScale
            origin.x = origin.x * changeScale + snapShot!.frame.origin.x
            origin.y = origin.y * changeScale + snapShot!.frame.origin.y
            snapShot!.removeFromSuperview()
            snapShot = nil

        default:
            break
        }
    }
    
//    @objc func zoomingTheScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer)
//    {
//        switch pinchRecognizer.state {
//        case .changed, .ended:
//            scale *= pinchRecognizer.scale
//            pinchRecognizer.scale = 1.0
//        default:
//            break
//        }
//    }
    
    // Pan gesture delegate method
    
    @objc func panningAround(byReactingTo panRecognizer: UIPanGestureRecognizer)
    {
        switch panRecognizer.state {                                 // improved method for panning (tutorial)
        case .began:
            snapShot = self.snapshotView(afterScreenUpdates: false)
            snapShot!.alpha = 0.8
            self.addSubview(snapShot!)
        case .changed:
            let translation = panRecognizer.translation(in: self)
            snapShot!.center.x += translation.x
            snapShot!.center.y += translation.y
            panRecognizer.setTranslation(CGPoint.zero, in: self)
        case .ended:
            // add the transition to currently origin point, seperated to x and y dimension
            origin.x += snapShot!.frame.origin.x
            origin.y += snapShot!.frame.origin.y
            snapShot!.removeFromSuperview()
            snapShot = nil
        default:
            break
        }
    }
    
//    @objc func panningAround(byReactingTo panRecognizer: UIPanGestureRecognizer)
//    {
//        switch panRecognizer.state {
//        case .changed, .ended:
//            let translation = panRecognizer.translation(in: self)
//            origin.x += translation.x
//            origin.y += translation.y
//            panRecognizer.setTranslation(CGPoint.zero, in: self)
//        default:
//            break
//        }
//    }
    
    // Tap gesture delegate method
    @objc func tappingToSetTheOriginPoint(byReactingTo tapRecognizer: UITapGestureRecognizer)
    {
        if tapRecognizer.state == .ended {
            origin = tapRecognizer.location(in: self)
        }
    }

    
    

}




