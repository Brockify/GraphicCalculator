//
//
// 11/29/2016
// Author: Brock D'Amico
//
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, GraphViewDelegate {
    
    //setup the gestures from GraphView class
    let Pan: Selector = #selector(GraphView.moveGraph(_:))
    let Origin = "GraphViewController.Origin"
    
    //render the UI from the operand stack
    var operandStack: [String] = [] {
        didSet{
            renderUI()
        }
    }
   
    //update the UI with the new display information (title) if available
    private func renderUI() {
        graphView?.setNeedsDisplay()
        if let operandLast = operandStack.last  {
            title = operandLast
        }
    }
    
    //UI IBOutlet set to display the GraphView
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            //set the delegates for the GraphView
            graphView.delegate = self
            graphView.dataSource = self
            
            //add pan gestures
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: Pan))
        }
    }
    
    //load user defaults from IOS
    private let loggedInUserDefaults = NSUserDefaults.standardUserDefaults()
    
    //setup the brain and import calculator brain
    private let brain = CalculatorBrain()
    
    //set up the graph (delegate)
    func graphForGraphView(xAxisValue: CGFloat, sender: GraphView) -> CGPoint? {
        brain.variableValues["M"] = Double(xAxisValue)
        
        if let y = brain.evaluate() {
            let mainPoint = CGPoint(x: xAxisValue, y: CGFloat(y))
            if !mainPoint.x.isNormal || !mainPoint.y.isNormal {
                return nil
            } else {
                return mainPoint
            }
        }
        return nil
    }
    
    //setup program graph object
    //getter and setter
    var programGraph: AnyObject {
        get {
            return brain.programGraph
        }
        set {
            brain.programGraph = newValue
        }
    }
    
    //sets the graph origin
    func moveOrigin(origin: CGPoint, sender: GraphView) {
        loggedInUserDefaults.setObject(NSStringFromCGPoint(origin), forKey: Origin)
    }
}