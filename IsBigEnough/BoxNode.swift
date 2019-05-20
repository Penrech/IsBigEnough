//
//  BoxNode.swift
//  IsBigEnough
//
//  Created by Pau Enrech on 16/05/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import SceneKit

class BoxNode: SCNNode {
    override init() {
        super.init()
        self.geometry = SCNBox(width: 0.7304, height: 0.4337, length: 0.055, chamferRadius: 0)
        //self.pivot = SCNMatrix4MakeTranslation(0, 0, -0.05)
        
        //Pruebas luz
        // Create the reflective material and apply it to the sphere
        let reflectiveMaterial = SCNMaterial()
        reflectiveMaterial.lightingModel = .physicallyBased
        reflectiveMaterial.metalness.contents = 1.0
        reflectiveMaterial.roughness.contents = 0
        self.geometry?.firstMaterial = reflectiveMaterial

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }}
