//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Brock D'Amico on 9/29/16.
//  Copyright © 2016 Brock D'Amico. All rights reserved.
//

import Foundation

class CalculatorBrain
{
    var pastSymbol = ""
    var displayFinal = ""

    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case UnaryOperation(String, (Double) -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        case ClearOperation(String)
        case SetM(String)
        case PiOperation((String))
        var description: String{
            get{
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .PiOperation:
                    return "⊓"
                case .ClearOperation:
                    return "C"
                case .SetM(let symbol):
                    return "\(symbol)"
                }
            }
        }
    }
    
    private var opStack = [Op]()
    private var knownOps = [String:Op]()
    var variableValues = [String:Double]()
    
    init () {
        func learnOps(op: Op) {
            knownOps[op.description] = op
        }
        learnOps(Op.BinaryOperation("✖️", *))
        learnOps(Op.BinaryOperation("➗"){$1 / $0})
        learnOps(Op.BinaryOperation("➕", +))
        learnOps(Op.BinaryOperation("➖"){$1 - $0})
        learnOps(Op.UnaryOperation("cos", cos))
        learnOps(Op.UnaryOperation("sin", sin))
        learnOps(Op.UnaryOperation("√", sqrt))
        learnOps(Op.PiOperation("⊓"))
        learnOps(Op.ClearOperation("C"))
        learnOps(Op.SetM(">M"))
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        let s = "hi"
        if let message = s as? String {
            
        }
    
    
    if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch(op) {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            case .PiOperation:
                return (M_PI, remainingOps)
            case .ClearOperation(_):
                clear()
            case .SetM(let symbol):
                if let variableValue = variableValues[symbol] {
                    return (variableValue, remainingOps)
                }
            }
        }
        return (nil, ops)
    }
    
    //create a variable to call to format
    var programGraph: AnyObject {
        get {
            return opStack.map { $0.description}
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var OpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps [opSymbol] {
                        OpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        OpStack.append(.Operand(operand))
                    } else {
                    OpStack.append(.SetM(opSymbol))
                    }
                }
                opStack = OpStack
            }
        }
    }
    
    private func history(currentDescription: [String], ops: [Op]) -> (accumulatedDescription: [String], remainingOps: [Op]) {
        var accumulatedDescription = currentDescription
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeFirst()
            switch op {
            case .Operand(_):
                accumulatedDescription.append(op.description)
                return history(accumulatedDescription, ops: remainingOps)
            case .UnaryOperation(let symbol, _):
                if !accumulatedDescription.isEmpty {
                    let unaryOperand = accumulatedDescription.removeLast()
                    accumulatedDescription.append(symbol + "(\(unaryOperand))")
                    let (newDescription, remainingOps) = history(accumulatedDescription, ops: remainingOps)
                    return (newDescription, remainingOps)
                }
            case .PiOperation(_):
                accumulatedDescription.append(op.description)
                return history(accumulatedDescription, ops: remainingOps)
            case .BinaryOperation(let symbol, _):
                if !accumulatedDescription.isEmpty {
                    let binaryOperandLast = accumulatedDescription.removeLast()
                    if !accumulatedDescription.isEmpty {
                        let binaryOperandFirst = accumulatedDescription.removeLast()
                        if op.description == remainingOps.first?.description {
                            accumulatedDescription.append("(\(binaryOperandFirst)" + symbol + "\(binaryOperandLast))")
                        } else {
                            accumulatedDescription.append("\(binaryOperandFirst)" + symbol + "\(binaryOperandLast)")
                        }
                        return history(accumulatedDescription, ops: remainingOps)
                    } else {
                        accumulatedDescription.append("?" + symbol + "\(binaryOperandLast)")
                        return history(accumulatedDescription, ops: remainingOps)
                    }
                } else {
                    accumulatedDescription.append("?" + symbol + "?")
                    return history(accumulatedDescription, ops: remainingOps)
                }
            case .SetM(let Symbol):
                accumulatedDescription.append(Symbol)
                return history(accumulatedDescription, ops: remainingOps)
            default:
                return history(accumulatedDescription, ops: remainingOps)
            }
        }
        return (accumulatedDescription, ops)
    }

    
    //save variables to variable stack
    func saveToVariableValues(name: String, value: Double)
    {
        variableValues[name] = value
    }
    
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    
    var description: String {
        let (descriptionArray, _) = history([String](), ops: opStack)
        return descriptionArray.joinWithSeparator(", ")
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.SetM(symbol))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
 
    //function for clearing the console
    func clear() -> Double? {
        opStack.removeAll()
        displayFinal = ""
        return evaluate()
    }
}
