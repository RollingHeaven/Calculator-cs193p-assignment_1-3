//
//  ViewController.swift
//  Calculator
//
//  Created by William on 2017/9/13.
//  Copyright © 2017年 Stanford. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    

    
    
    @IBOutlet weak var descriptionDisplay: UILabel!
    
    @IBOutlet weak var displayMValue: UILabel!
    
    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var graphButton: UIButton!
    @IBOutlet weak var graphButtonCompactHeight: UIButton!
    
    var graphButtonDefaultColor: UIColor?
    
    
    var userIsInTheMiddleTyping = false
    
    private let fractionDigitFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    
    private let fractionDigitFormatterForMemoryValueDisplay: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    
    private let decimalSeperator = NumberFormatter().decimalSeparator!
    
    private var variables = [String: Double]() {
        didSet {
            // -----------the statement below was used to present multi-variables value ----------- //
            //            displayMValue.text = variables.flatMap{$0 + ": " + fractionDigitFormatter.string(from: NSNumber(value: $1))!}.joined(separator: ", ")
            if let mValue = variables["M"] {
                displayMValue.text = "M : " + fractionDigitFormatterForMemoryValueDisplay.string(from: NSNumber(value: mValue))!
            }
            
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        graphButtonDefaultColor = UIColor(red: 0.0/255.0, green: 128.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.orange]
    }
    
    
    

    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleTyping {
            let textCurrentlyInDisplay = display.text!
            if digit != decimalSeperator || !textCurrentlyInDisplay.contains(decimalSeperator) {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            switch digit {
            case decimalSeperator:
                display.text = "0" + decimalSeperator
            case "0":
                if display.text == "0" {
                    return
                }
                // fallthrough for preventing empty display value
                fallthrough
            default:
                display.text = digit
            }
            userIsInTheMiddleTyping = true
        }
        
    }
    
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            display.text = fractionDigitFormatter.string(from: NSNumber(value: newValue))
        }
        
    }
    
    @IBAction func undo(_ sender: UIButton) {
        if userIsInTheMiddleTyping {
            display.text!.remove(at: (display.text!.index(before: display.text!.endIndex)))
            if display.text!.isEmpty || display.text == "0" {
                display.text = "0"
                userIsInTheMiddleTyping = false
            }
        } else {
            brain.undo()
            displayResult()
        }
        
    }
    
    @IBAction func callMemory(_ sender: UIButton) {
        brain.setOperand(variable: "M")
        userIsInTheMiddleTyping = false
        displayResult()
    }
    
    @IBAction func storeToMemory(_ sender: UIButton) {
        variables["M"] = displayValue
        userIsInTheMiddleTyping = false
        displayResult()
        
    }
    
    @IBAction func clean(_ sender: UIButton) {
        displayValue = 0
        descriptionDisplay.text = " "
        displayMValue.text = " "
        brain.clean()
//         another way to clean model is creating a new model instance and throw the old one, like below
//         brain = CalculatorBrain()
        variables = Dictionary<String, Double>()
        userIsInTheMiddleTyping = false
        graphButton.setTitleColor(graphButtonDefaultColor, for: .normal)
    }
    
    private func displayResult() {
        let evaluated = brain.evaluate(variabls: variables)
        
        if let error = evaluated.errorReport {
            display.text = error
        } else if let result = evaluated.result {
            displayValue = result
        }
        
        if evaluated.description != nil {
            if evaluated.description != "" {
                descriptionDisplay.text = evaluated.description! + (evaluated.isPending ? "...": "=")
            } else {
                descriptionDisplay.text = " "
            }
        }

        if evaluated.isPending {
            graphButton.setTitleColor(UIColor.red, for: .normal)
            graphButtonCompactHeight.setTitleColor(UIColor.red, for: .normal)
        } else {
            graphButton.setTitleColor(graphButtonDefaultColor, for: .normal)
            graphButtonCompactHeight.setTitleColor(graphButtonDefaultColor, for: .normal)
        }
    }
    
    private var brain = CalculatorBrain()
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            // ask brain perform operation
            brain.performOperation(mathematicalSymbol)
        }
        displayResult()
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let graphViewController = segue.destination.content as? GraphingViewController,
            let identifier = segue.identifier {
            if identifier == "Show Graph" {
                graphViewController.setTheBrain(with: brain)
                graphViewController.navigationItem.title = brain.evaluate().description
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "Show Graph" && brain.evaluate().isPending {
            return false
        }
        return true
    }
    
    // assign the delegate of split view controller to make it show the master scene after lauching
    // the best way to set the delegate method and preventing detail VC collasps on master VC is
    // set it at the awakeFromNib, here we can ensure the split view has been build
    // viewDidLoaded is too late for this delegate method to prevent the view collasping action
    override func awakeFromNib() {
        super.awakeFromNib()
        self.content.splitViewController?.delegate = self
        
    }
    
    
}

// Make this controller conforms the SplitViewDelegate Protocol and stop the collasping of the secondary viewcontroller
// (i.e. preventing the detail controller show on screen if no function stack in that controller's brain(model)

extension CalculatorViewController: UISplitViewControllerDelegate {
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
        ) -> Bool {
        if primaryViewController.content == self {
            if let graphVC = secondaryViewController.content as? GraphingViewController, graphVC.isBrainFunctionStackEmpty {
                return true
            }
        }
        return false
    }
}

// a friendly extension for convenience to access the content of navicontroller
// if navicontroller exist, access its visible controller, or return self
extension UIViewController {
    var content: UIViewController {
        if let nvcon = self as? UINavigationController {
            return nvcon.visibleViewController ?? self
        } else {
            return self
        }
    }
}
