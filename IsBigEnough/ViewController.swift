//
//  ViewController.swift
//  IsBigEnough
//
//  Created by Pau Enrech on 16/05/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var inchesLabel: UILabel! {
        didSet{
            if currentTv == nil {
                inchesLabel.isHidden = true
            }
        }
    }
    @IBOutlet weak var addResetButton: UIButton! {
        didSet{
            addResetButton.isEnabled = false
        }
    }
    
    
    @IBAction func addResetTv(_ sender: Any) {
        if currentTv != nil {
            resetTV()
        } else {
            addTvToPlane()
        }
        
    }
    
    let addImage = UIImage(named: "round-add_circle_outline-24px")
    let clearImage = UIImage(named: "round-highlight_off-24px")
    var currentTv: SCNNode?
    var currentWall: SCNNode?
    var currentAnchor: ARPlaneAnchor?
    var tvNode: SCNNode?
    var planes = [ARPlaneAnchor]()
    var latestTranslatePos: CGPoint?
    var previusLocation: ARWorldMap?
    var currentScale: CGFloat = 1

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        showScanPoints(show: true)
        
       // Set the scene to the view
        sceneView.scene = SCNScene()
        
        if let tvScene = SCNScene(named: "art.scnassets/tv.scn") {
            tvNode = SCNNode()
            print("Root node: \(tvScene.rootNode.childNodes)")
            for childNode in tvScene.rootNode.childNodes {
                print("Nodo: \(childNode)")
                tvNode?.addChildNode(childNode)
            }
        }

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestured))
        let pinchToScale = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchToScale)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        stateLabel.text = "Searching for walls"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView {
            statusBarView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        }
        
        configureAndLoadSession()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        storeSessionWorldMap()

    }
    
    func showScanPoints(show: Bool) {
        if show {
            sceneView.debugOptions = [.showFeaturePoints]
        } else {
            sceneView.debugOptions = []
        }
    }

   public func configureAndLoadSession(){
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        configuration.isLightEstimationEnabled = true
        configuration.environmentTexturing = ARWorldTrackingConfiguration.EnvironmentTexturing.automatic
        
        configuration.initialWorldMap = previusLocation
        if previusLocation == nil {
            resetTV()
        }
        
        stateLabel.text = "Initializing"
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    public func storeSessionWorldMap(){
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            if let worldMap = worldMap {
                self.previusLocation = worldMap
                print("Sesion guardada con \(worldMap)")
            }
        }
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc func panGestured(sender: UIPanGestureRecognizer) {
        let position = sender.location(in: sceneView)
        let state = sender.state
        
        if (state == .failed || state == .cancelled) {
            return
        }
        
        if (state == .began) {
            let hitTestTV = self.sceneView.hitTest(position, options: [SCNHitTestOption.searchMode: 1 ])
            guard let _ = hitTestTV.filter({ $0.node == currentTv?.childNodes.first?.childNodes.last }).first else { turnTv(on: false); return }
            
            turnTv(on: true)
            latestTranslatePos = position
        }
        else if let tv = currentTv, latestTranslatePos != nil {
            
            // Translate virtual object
            let deltaX = Float(position.x - latestTranslatePos!.x)/700
            let deltaY = Float(position.y - latestTranslatePos!.y)/700
            
            tv.localTranslate(by: SCNVector3Make(deltaX, -deltaY, 0.0 ))
            
            latestTranslatePos = position
            
            if (state == .ended) {
                latestTranslatePos = nil
            }
        }
        
    }
    
    @objc func pinchGesture(sender: UIPinchGestureRecognizer) {
        let state = sender.state
        let maxSize: CGFloat = 4
        let minSize: CGFloat = 0.5
        
        guard let tv = currentTv else { return }
        
        if (state == .failed || state == .cancelled) {
            return
        }
    
        if state == .began || state == .changed {
            let scale = sender.scale
            
            let newScale = max(minSize, min(maxSize, scale * CGFloat(tv.scale.x)))
            tv.scale = SCNVector3(newScale, newScale, newScale)
            sender.scale = 1
            
            currentScale = newScale
            calculateInches(scale: newScale)

        }
        
    }
    
    func calculateInches(scale: CGFloat){
        let standardValue = 32 //Inches
        
        let currentInches = CGFloat(standardValue) * scale
        let inchesNormalized = round(currentInches * 2) / 2
        let decimal = modf(inchesNormalized).1
        
        let formatString = decimal == 0 ? "Inches: %.0f\"" : "Inches: %.1f\""
        
        self.inchesLabel.text = String.init(format: formatString, inchesNormalized)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches began")
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        
        
    }
  
    
    func addTvToPlane(){
        guard let currentAnchor = currentAnchor, let node = sceneView.node(for: currentAnchor) else { return }
 
        currentTv = tvNode!
        currentTv!.eulerAngles.x = -Float.pi / 2.0
        
        node.childNodes.first?.removeFromParentNode()
        node.addChildNode(currentTv!)
        self.setLabel(text: "Tv mounted")
        
        inchesLabel.isHidden = false
        addResetButton.setBackgroundImage(clearImage, for: .normal)
        
        showScanPoints(show: false)
        
    }
    
    func resetTV(){
        guard let currentAnchor = currentAnchor, let node = sceneView.node(for: currentAnchor) else { return }
        
        node.childNodes.first?.removeFromParentNode()
        currentTv = nil

        self.setLabel(text: "Searching walls")
        
        inchesLabel.isHidden = true
        addResetButton.setBackgroundImage(addImage, for: .normal)
        
        showScanPoints(show: true)
        
        enableAddButton(enable: false)
    }
 
    
    func setLabel(text: String){
        DispatchQueue.main.async {
            self.stateLabel.text = text
        }
    }
    
    func enableAddButton(enable: Bool){
        DispatchQueue.main.async {
            self.addResetButton.isEnabled = enable
        }
    }
    
    func turnTv(on: Bool){
        guard let currentTV = currentTv, let screen =  currentTV.childNodes.first?.childNodes.filter({ $0.name == "pantalla" }).first else { return }
        
        if on {
            screen.geometry?.materials.first?.emission.intensity = 1.0
        } else {
            screen.geometry?.materials.first?.emission.intensity = 0.0
        }
    }
    

}
extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    
        if let planeAnchor = anchor as? ARPlaneAnchor {
            
            updatePlane(planeAnchor: planeAnchor)
            
            guard currentTv == nil else { return }
            
            if planeAnchor != currentAnchor {
                unColorPlane(planeAnchor: currentAnchor)
                colorPlane(planeAnchor: planeAnchor)
            }
        
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        if let planeAnchor = anchor as? ARPlaneAnchor {
            
            planes.append(planeAnchor)
            
        }
    }
    
    func updatePlane(planeAnchor: ARPlaneAnchor?){
        guard let planeAnchor = planeAnchor, let associatedNode = sceneView.node(for: planeAnchor), let plane = associatedNode.geometry as? SCNPlane else { return }
        
        associatedNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    func colorPlane(planeAnchor: ARPlaneAnchor?) {
        guard let planeAnchor = planeAnchor, let associatedNode = sceneView.node(for: planeAnchor), associatedNode.childNodes.count < 1 else { return }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        plane.materials.first?.diffuse.contents = UIColor(red: 3/255, green: 169/255, blue: 244/255, alpha: 0.50)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0.0, planeAnchor.center.z)
        
        planeNode.eulerAngles.x = -Float.pi / 2.0
        
        //Añadimos el node
        associatedNode.addChildNode(planeNode)
        
        currentAnchor = planeAnchor
        setLabel(text: "Wall detected")
        
        enableAddButton(enable: true)
        
    }
    func unColorPlane(planeAnchor: ARPlaneAnchor?) {
        guard let planeAnchor = planeAnchor, let associatedNode = sceneView.node(for: planeAnchor), associatedNode.childNodes.count > 0 else { return }
        
        associatedNode.childNodes.first?.removeFromParentNode()
    }
}
