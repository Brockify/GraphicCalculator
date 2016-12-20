import UIKit

//setup GraphViewDataSource class
protocol GraphViewDataSource: class {
    func graphForGraphView(xAxisValue: CGFloat, sender: GraphView) -> CGPoint?
}

//import two functions from GraphViewController class
@objc protocol GraphViewDelegate {
    //scales the map, moves origin point
    optional func moveOrigin(origin: CGPoint, sender: GraphView)
}

//setup a designable UIView
@IBDesignable
class GraphView: UIView {
    //set graph lines to green color
    //setNeedsDisplay is a function from the UIView
    @IBInspectable var colorOfAxis: UIColor = UIColor.greenColor() { didSet { setNeedsDisplay()} }
    @IBInspectable var pointsPerUnits: CGFloat = 100 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    //create a variable to hold the View snapshot
    var snapshot: UIView?
    
    //set the resolution for the graph
    var graphResolution: CGFloat {
        get {
            return contentScaleFactor
        }
    }
    
    //setup new axis points
    var newAxisOrigin: CGPoint?
    var maxYValue: CGFloat = 0.0
    var minYValue: CGFloat = 0.0
    
    //setup variable with getter and setter for origin axis (changes based on pan)
    var axisOrigin : CGPoint {
        get {
            return newAxisOrigin ?? convertPoint(center, fromView: superview) }
        set {
            newAxisOrigin = newValue
            delegate?.moveOrigin!(newValue, sender: self)
            setNeedsDisplay()
        }
    }
    
    //setup the rectangle frame for the graph
    var rectangleFrame : CGRect {
        return convertRect(frame, fromView: superview)
    }
    
    //setup datasource, delegate, and AxesDrawer
    let axesDrawer = AxesDrawer()
    var dataSource: GraphViewDataSource?
    var delegate: GraphViewDelegate?
    
    
    //override the draw rectangle function
    override func drawRect(rect: CGRect) {
        axesDrawer.color = colorOfAxis
        axesDrawer.contentScaleFactor = graphResolution
        axesDrawer.drawAxesInRect(rectangleFrame, origin: axisOrigin, pointsPerUnit: pointsPerUnits)
        drawGraph(axisOrigin, pointsPerUnit: pointsPerUnits)
        
    }
    
    //Function is used to draw the y = x + b graph
    private func drawGraph(origin: CGPoint, pointsPerUnit: CGFloat ) {
        let path = UIBezierPath()
        
        var xValue = bounds.minX
        
        while xValue <= bounds.maxX {
            let scaleAndOriginAccountedValue = (xValue - origin.x) / pointsPerUnits
            
            if let point = dataSource?.graphForGraphView(scaleAndOriginAccountedValue, sender: self) {
                let convertedPointToDraw = CGPoint(x: (point.x * pointsPerUnits) + origin.x, y: origin.y - (point.y * pointsPerUnits) )
                if let alignedPoint = createAlignedPoint(convertedPointToDraw.x, y: convertedPointToDraw.y, insideBounds: bounds) {
                    if !path.empty { path.addLineToPoint(alignedPoint) }
                    path.moveToPoint(alignedPoint)
                }
                
                if maxYValue < point.y { maxYValue = point.y }
                if minYValue > point.y { minYValue = point.y }
            }
            xValue += 1 / graphResolution
        }
        path.stroke()
    }

    // Moves the entire graph
    func moveGraph(gesture : UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            snapshot = self.snapshotViewAfterScreenUpdates(false)
            snapshot?.alpha = 0.8
            self.addSubview(snapshot!)
        case .Changed:
            let translation = gesture.translationInView(self)
            snapshot!.center.x += translation.x
            snapshot!.center.y += translation.y
            gesture.setTranslation(CGPointZero, inView: self)
        case .Ended:
            let newOrigin = CGPoint(x: axisOrigin.x + snapshot!.frame.origin.x, y: axisOrigin.y + snapshot!.frame.origin.y)
            axisOrigin = newOrigin
            snapshot!.removeFromSuperview()
            snapshot = nil
            
        default: break
        }
    }
    
    //create and return the new aligned point
    private func createAlignedPoint(x: CGFloat, y: CGFloat, insideBounds: CGRect? = nil) -> CGPoint?
    {
        let point = CGPoint(x: alignPoint(x), y: alignPoint(y))
        if let permissibleBounds = insideBounds {
            if (!CGRectContainsPoint(permissibleBounds, point)) {
                return nil
            }
        }
        return point
    }
    
    //align a specific point
    private func alignPoint(coordinate: CGFloat) -> CGFloat {
        return round(coordinate * graphResolution) / graphResolution
    }
    
}
