//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by William on 2017/9/13.
//  Copyright © 2017年 Stanford. All rights reserved.
//

import Foundation


struct CalculatorBrain {
    
    private var descriptionFractionFormatter = NumberFormatter()  //---------------(preparing)------------------<<<
    
    private var workingStack = [Element]()   // should be private
    
    var isFunctionStackEmpty: Bool {
        return workingStack.isEmpty
    }

    private enum Element {
        case operand(Double)
        case operation(String)
        case variable(String)
    }
    
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double)->Double, (String)->String)
        case binaryOperation((Double, Double) -> Double, (String, String)->String)
        case equals
        case nullaryOperation(()->Double, String)
    }
    
    private enum ErrorOperation {
        case unaryOperation((Double)->String?)
        case binaryOperation((Double, Double)->String?)
    }
    
    private var operations: Dictionary<String, Operation> = [
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "√": Operation.unaryOperation(sqrt, {"√(" + $0 + ")"}),
        "cos": Operation.unaryOperation(cos, {"cos(" + $0 + ")"}),
        "sin": Operation.unaryOperation(sin, {"sin(" + $0 + ")"}),
        "tan": Operation.unaryOperation(tan, {"tan(" + $0 + ")"}),
        "±": Operation.unaryOperation({-$0},{"-(" + $0 + ")"}),
        "+": Operation.binaryOperation({$0 + $1}, {$0 + "+" + $1}),
        "−": Operation.binaryOperation({$0 - $1}, {$0 + "-" + $1}),
        "×": Operation.binaryOperation({$0 * $1}, {$0 + "×" + $1}),
        "÷": Operation.binaryOperation({$0 / $1}, {$0 + "÷" + $1}),
        "xʸ": Operation.binaryOperation({pow($0, $1)}, {"(" + $0 + ")pow(" + $1 + ")"}),
        "=": Operation.equals,
        "Ran": Operation.nullaryOperation({Double(arc4random()) / Double(UInt32.max)}, "rand()")
    ]
    
    private var errorOperations: Dictionary<String, ErrorOperation> = [
        "√": ErrorOperation.unaryOperation{ $0 < 0 ? "Square with negative number" : nil },
        "÷": ErrorOperation.binaryOperation{ ($0 == 0 && $1 == 0) || ( $1 == 0) ? "Divided by 0" : nil}
    ]
    

    
    mutating func setOperand(_ operand: Double) {
        workingStack.append(.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        workingStack.append(.variable(named))
    }
    
    mutating func performOperation(_ symbol: String) {
        workingStack.append(.operation(symbol))
        
    }
    
    mutating func clean() {
        if !workingStack.isEmpty {
            workingStack.removeAll()
        }
    }
    
    mutating func undo() {
        if !workingStack.isEmpty {
            workingStack.removeLast()
        }
    }
    
    func evaluate(variabls: Dictionary<String, Double>? = nil) -> (result: Double?, isPending: Bool, description: String?, errorReport: String?)
    {
        var accumulator: (Double, String)?
        
        var errorReport: String?
        
        var pendingBinaryOperation: PendingBinaryOperation?
        
        struct PendingBinaryOperation {
            let function: (Double, Double) -> Double
            let symbol: String
            let firstOperand: (Double, String)
            let description: (String, String) -> String
            
            func perform(with secondOperand: (Double, String)) -> (Double, String) {
                return (function(firstOperand.0, secondOperand.0), description(firstOperand.1, secondOperand.1))
            }
        }
        
        var result: Double? {
            if accumulator != nil {
                return accumulator!.0
            } else {
                return nil
            }
        }
        
        var description: String? {
            get {
                if pendingBinaryOperation != nil {
                    return pendingBinaryOperation!.description(pendingBinaryOperation!.firstOperand.1, accumulator?.1 ?? "")
                } else {
                    return accumulator?.1
                }
            }
        }
        
        func performPendingBinaryOperation() {
            if pendingBinaryOperation != nil && accumulator != nil {
                if let errorOperation = errorOperations[pendingBinaryOperation!.symbol],
                    case .binaryOperation(let errorFunction) = errorOperation {
                    errorReport = errorFunction(pendingBinaryOperation!.firstOperand.0, accumulator!.0)
                }
                accumulator = pendingBinaryOperation!.perform(with: (accumulator!.0, accumulator!.1))
                pendingBinaryOperation = nil
            }
        }
        

        for element in workingStack {
            switch element {
            case .operand(let value):
                accumulator = (value, "\(value)")
            case .operation(let symbol):
                if let operation = operations[symbol] {
                    switch operation {
                    case .constant(let value):
                        accumulator = (value, symbol)
                    case .unaryOperation(let function, let description):
                        if accumulator != nil {
                            if let errorOperation = errorOperations[symbol],
                                case .unaryOperation(let errorFunction) = errorOperation {
                                errorReport = errorFunction(accumulator!.0)
                            }
                            accumulator = (function(accumulator!.0), description(accumulator!.1))
                        }
                    case .binaryOperation(let function, let description):
                        if accumulator != nil {
                            performPendingBinaryOperation()
                            pendingBinaryOperation = PendingBinaryOperation(function: function, symbol: symbol, firstOperand: (accumulator!.0, accumulator!.1), description: description)
                            accumulator = nil
                        }
                    case .equals:
                        performPendingBinaryOperation()
                    case .nullaryOperation(let function, let description):
                        accumulator = (function(), description)
                    }
                }
            case .variable(let symbol):
                if let value = variabls?[symbol] {
                    accumulator = (value, symbol)
                } else {
                    accumulator = (0, symbol)
                }
            }
        }
        
        return (result, pendingBinaryOperation != nil, description ?? " ", errorReport)
    }
    
    

    
    
// --------( API for deprecating )--------------------------
    @available(*, deprecated, message: "no longer need...")
    var resultIsPending: Bool {
        get {
            return evaluate().isPending
        }
    }
    
    @available(*, deprecated, message: "no longer need...")
    var description: String? {
        get {
            return evaluate().description
        }
    }
    
    @available(*, deprecated, message: "no longer need...")
    var result: Double? {
        get {
            return evaluate().result
        }
    }
// --------( API for deprecating )--------------------------
    
    
    
    
    
}
