//
//  GeolocationMarkerNode.swift
//  FMEAR
//
//  Created by Angus Lau on 2019-10-17.
//  Copyright © 2019 Safe Software Inc. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

class GeolocationMarkerNode: SCNNode {
    
    var textGeometry: SCNText?
    var markerGeometry: SCNCone
    var anchor: Anchor?
    
    override init() {

        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = UIColor.white

        let height: CGFloat = 0.5 // meter
        let radius: CGFloat = height * 0.01
        self.markerGeometry = SCNCone(topRadius: radius, bottomRadius: 0, height: height)
        self.markerGeometry.firstMaterial = material
        let markerNode = SCNNode(geometry: markerGeometry)
        markerNode.simdPosition = simd_float3(Float(0.0), Float(height * 0.5), Float(0.0))

        super.init()

        self.addChildNode(markerNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var text: String = "" {
        didSet {
            
            if !text.isEmpty {
                if textGeometry == nil {
                    
                    let fontSize = UserDefaults.standard.float(for: .labelFontSize)
                    
                    textGeometry = SCNText(string: "", extrusionDepth: 0.0)
                    textGeometry!.firstMaterial = markerGeometry.firstMaterial
                    textGeometry!.font = UIFont(name: "Helvetica", size: CGFloat(fontSize))
                    let textNode = SCNNode(geometry: textGeometry)
                    let billboardConstraint = SCNBillboardConstraint()
                    billboardConstraint.freeAxes = SCNBillboardAxis.Y
                    textNode.constraints = [billboardConstraint]
                    textNode.scale = SCNVector3(0.01, 0.01, 0.01)
                    textNode.simdPosition = simd_float3(Float(0.0), Float(markerGeometry.height), Float(0.0))
                    addChildNode(textNode)
                }
                
                textGeometry!.string = text
            }
        }
    }
    
    var color: UIColor = .white {
        didSet {
            textGeometry?.firstMaterial?.diffuse.contents = color
            markerGeometry.firstMaterial?.diffuse.contents = color
        }
    }
    
    var geolocation: CLLocation? {
        didSet {
            updatePosition()
        }
    }

    var userLocation: CLLocation? {
        didSet {
            updatePosition()
        }
    }
    
    func calculatePosition() -> SCNVector3? {
        if let userLocation = self.userLocation, let geolocation = self.geolocation {
            
            // Latitude: geomarker - user location
            let deltaLatitude = CLLocation(latitude: geolocation.coordinate.latitude, longitude: userLocation.coordinate.longitude).distance(from: userLocation)
            
            // Longitude: geomarker - user location
            let deltaLongitude = CLLocation(latitude: userLocation.coordinate.latitude, longitude: geolocation.coordinate.longitude).distance(from: userLocation)

            // North: -Z, South: +Z, East: +X, West: -X, Up: +Y, Down: -Y
            return SCNVector3(Float(deltaLongitude), self.position.y, -Float(deltaLatitude))
        } else {
            return nil
        }
    }
    
    func updatePosition() {
        if let userLocation = self.userLocation, let geolocation = self.geolocation {
            let newLocation = calculatePosition()
            if let newLocation = newLocation {
                move(to: newLocation)
            }
            
            let shouldDrawGeomarker = !(UserDefaults.standard.bool(for: .drawGeomarker))
            isHidden = shouldDrawGeomarker
        } else {
            isHidden = true
        }
    }
    
    func move(to location: SCNVector3) {
        let action = SCNAction.move(to: location, duration: 0.0)
        action.timingMode = .easeInEaseOut
        runAction(action)
    }
}
