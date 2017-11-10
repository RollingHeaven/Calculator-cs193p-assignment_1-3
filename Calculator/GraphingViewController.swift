//
//  GraphingViewController.swift
//  Calculator
//
//  Created by William on 2017/10/2.
//  Copyright © 2017年 Stanford. All rights reserved.
//

import UIKit

class GraphingViewController: UIViewController, GraphViewDataSource {


    @IBOutlet weak var graphView: GraphingView! {
        didSet {
            graphView.graphDataSource = self
            // pinch gesture
            let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.zooming(byReactingTo:)))
            graphView.addGestureRecognizer(pinchGestureRecognizer)
            // pan gesture
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panning(byReactingTo:)))
            panGestureRecognizer.minimumNumberOfTouches = 1
            panGestureRecognizer.maximumNumberOfTouches = 1
            graphView.addGestureRecognizer(panGestureRecognizer)
            // tap gesture
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapping(byReactingTO:)))
            tapGestureRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapGestureRecognizer)
            
            if !isResetOriginPoint {
                // graph view controller only provide origin when its hold origin data, otherwise reset origin by view
                graphView.origin = origin
            }
            graphView.scale = scale         // definition including reset code for scale to 1.0
            
        }
    }
    
    
    private var brain = CalculatorBrain()
    
     // data source protocol methods
    func y(x: CGFloat) -> CGFloat? {
        if let result = brain.evaluate(variabls: ["M": Double(x)]).result {
            return CGFloat(result)
        } else {
            return nil
        }
    }
    
    // set the brain, use of propagating the data from master view controller
    func setTheBrain(with calculatorBrain: CalculatorBrain) {
        self.brain = calculatorBrain
    }
    // check whether the brain in this controller have the function stack(data) in it
    var isBrainFunctionStackEmpty: Bool {
        return brain.isFunctionStackEmpty
    }

    
    private struct DefaultKeys {
        static let origin = "GraphViewController.origin"
        static let scale = "GraphViewController.scale"
        //static let program = "GraphViewController.program"
    }
    
    private let defaults = UserDefaults.standard
    
    var scale: CGFloat {
        get {
            return defaults.object(forKey: DefaultKeys.scale) as? CGFloat ?? 1.0
        }
        set {
            defaults.set(newValue, forKey: DefaultKeys.scale)
        }
    }
    var origin: CGPoint {
        get {
            var origin = CGPoint()
            if let originData = defaults.object(forKey: DefaultKeys.origin) as? [CGFloat] {
                origin.x = originData.first!
                origin.y = originData.last!
            }
            return origin
        }
        set {
            defaults.set([newValue.x, newValue.y], forKey: DefaultKeys.origin)
        }
    }
    
    var isResetOriginPoint: Bool {
        if nil != defaults.object(forKey: DefaultKeys.origin) as? [CGFloat] {
            return false
        }
        return true
    }
    
    
    
    // gesture deleget method
    @objc func zooming(byReactingTo pinchRecognizer: UIPinchGestureRecognizer) {
        graphView.zoomingTheScale(byReactingTo: pinchRecognizer)
        if pinchRecognizer.state == .ended {
            scale = graphView.scale
            origin = graphView.origin
        }
    }

    @objc func panning(byReactingTo panningRecognizer: UIPanGestureRecognizer) {
        graphView.panningAround(byReactingTo: panningRecognizer)
        if panningRecognizer.state == .ended {
            origin = graphView.origin
        }
    }
    
    @objc func tapping(byReactingTO tapRecognizer: UITapGestureRecognizer) {
        graphView.tappingToSetTheOriginPoint(byReactingTo: tapRecognizer)
        if tapRecognizer.state == .ended {
            origin = graphView.origin
        }
    }
    
    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
