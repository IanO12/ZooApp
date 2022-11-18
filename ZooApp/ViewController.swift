//
//  ViewController.swift
//  ZooApp
//
//  Created by Ian J. O'Strander on 11/16/22.
//

import UIKit
import RealityKit
import ARKit
class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var LoadWorld: UIButton!
    @IBOutlet weak var newView: ARView!
    @IBOutlet weak var SaveWorld: UIButton!
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    var defaultConfiguration: ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.environmentTexturing = .automatic
            return configuration
        }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //         Load the "Box" scene from the "Experience" Reality File
        //        let boxAnchor = try! Experience.loadBox()
        
        //         Add the box anchor to the scene
        //       arView.scene.anchors.append(boxAnchor)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        newView.session.delegate = self
        
        setupARView()
        
        newView.addGestureRecognizer(UITapGestureRecognizer(target:self,action: #selector(handleTap(recognizer:))))
    }
    
    func setupARView(){
        newView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        newView.session.run(configuration)
    }
    
    @objc
    func handleTap(recognizer: UITapGestureRecognizer){
        let location = recognizer.location(in: newView)
        let results = newView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first{
            let anchor = ARAnchor(name: "Cube", transform: firstResult.worldTransform)
            newView.session.add(anchor: anchor)
        } else{
            print("Object Placement Failed")
        }
    }
    
    func placeObject(named entityName: String, for anchor: ARAnchor){
        let cube = MeshResource.generateBox(size: 0.3)
        let entity = ModelEntity(mesh: cube)
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        newView.scene.addAnchor(anchorEntity)
    }
    func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: url)
    }
    @IBAction func saveButtonAction(_ sender: Any) {
        print("Working")
        newView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                //self.showAlert(title: "No Map", message: error!.localizedDescription); return
                print("No map")
                return
            }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                try data.write(to: self.worldMapURL, options: [.atomic])
                //self.showAlert(message: "Map Saved")
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    func loadWorldMap(from url: URL) throws -> ARWorldMap {
        let mapData = try Data(contentsOf: url)
        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        else { throw ARError(.invalidWorldMap) }
        return worldMap
    }
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: worldMapURL)
    }
    @IBAction func loadButtonAction(_ sender: Any) {
        let worldMap: ARWorldMap = {
                    guard let data = mapDataFromFile
                        else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
                    do {
                        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                            else { fatalError("No ARWorldMap in archive.") }
                        return worldMap
                    } catch {
                        fatalError("Can't unarchive ARWorldMap from file data: \(error)")
                    }
                }()
        let configuration = self.defaultConfiguration
        configuration.initialWorldMap = worldMap
        newView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors{
            if let anchorName = anchor.name, anchorName == "Cube"{
                print(anchor)
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}
