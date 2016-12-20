//
//  ViewController.swift
//  Calculator
//
//  Created by Brock D'Amico on 9/13/16.
//  Copyright © 2016 Brock D'Amico. All rights reserved.
//

import UIKit

class CalculatorViewControler: UIViewController {
    
    private struct Calculator {
        static let SegueIdentifier = "Show Graph"
    }
    
    @IBOutlet weak var history: UILabel!
    @IBOutlet weak var display: UILabel!
    var brain = CalculatorBrain()
    var userIsInTheMiddleOfTypingANumber = false
    var operationSymbol = ""
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if(userIsInTheMiddleOfTypingANumber)
        {
            if(digit == ".")
            {
                if(display.text! == ".")
                {
                    
                } else {
                    display.text! = display.text! + digit
                }
            } else {
                display.text! = display.text! + digit
            }
        } else {
            display.text! = digit
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var destination = segue.destinationViewController
        
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        
        if let gvc = destination as? GraphViewController {
            if let identifier = segue.identifier {
                
                switch identifier {
                case Calculator.SegueIdentifier:
                    gvc.operandStack = brain.programGraph as? [String] ?? []
                    gvc.programGraph = brain.programGraph
                default: break
                }
            }
        }
    }

    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        
        if let operation = sender.currentTitle {
            if let result = brain.performOperation(operation) {
                displayValue = result
            }else{
                displayValue = 0
                history.text = ""
            }
        }
    }
    
    @IBAction func mRead(sender: AnyObject) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        displayValue = brain.pushOperand("M")
    }
    
    @IBAction func mSet(sender: AnyObject) {
        userIsInTheMiddleOfTypingANumber = false
        if displayValue != nil {
            brain.variableValues["M"] = displayValue!
        }
    }
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if let result = brain.pushOperand(displayValue!) {
            displayValue = result
        }else{
            displayValue = nil
        }
        userIsInTheMiddleOfTypingANumber = false
    }
    
    func multiply(num1: Double, num2:Double) -> Double
    {
        return num1 * num2
    }
    
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        
        set {
            if(newValue != nil)
            {
                display.text = " \(newValue!)"
            }
            history.text = "\(brain.description) ="
            userIsInTheMiddleOfTypingANumber = false
        }
    }
}
