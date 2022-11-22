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
    
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var LoadWorld: UIButton!
    @IBOutlet weak var newView: ARView!
    @IBOutlet weak var SaveWorld: UIButton!
    
    var entries : [ZooLookup] = []
    var info : [Data] = []
    var defualts = UserDefaults.standard
    
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()

    var name: String = ""
    var defaultConfiguration: ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.environmentTexturing = .automatic
            return configuration
        }
    
    
    @IBOutlet weak var deleteMaps: UIButton!
    @IBAction func deleteMapsAction(_ sender: Any) {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(defualts.array(forKey: "Maps") != nil){
            debugLabel.text = "THIS WORKED"
            info = defualts.array(forKey:"Maps") as! [Data]
            for i in info{
                entries.append(ZooLookup(name:"Something", data: i))
            }
        }
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
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        newView.debugOptions = [.showFeaturePoints]
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
//    func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
//        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
//        try data.write(to: url)
//    }
    @IBAction func saveButtonAction(_ sender: Any) {
        let alert = UIAlertController(
            title: "Enter Title",
            message: "Enter a Title for Your Zoo",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Name"
            field.returnKeyType = .continue
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in
            guard let name = alert.textFields![0].text, !name.isEmpty else{
                return
            }
            self.name = name
            self.saveWorldMap()
        }))
        present(alert, animated:true)
    }
    func saveWorldMap(){
        newView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                //self.showAlert(title: "No Map", message: error!.localizedDescription); return
                print("No map")
                return
            }
             do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                 try data.write(to: self.worldMapURL, options: [.atomic])
                 self.info.append(data)
                 self.defualts.set(self.info, forKey: "Maps")
                //self.showAlert(message: "Map Saved")
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
        var data: Data? {
            return try? Data(contentsOf: worldMapURL)
        }
        entries.append(ZooLookup(name:name, data: data!))
    }
    func loadWorldMap(from url: URL) throws -> ARWorldMap {
        let mapData = try Data(contentsOf: url)
        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        else { throw ARError(.invalidWorldMap) }
        let configuration = self.defaultConfiguration
        configuration.initialWorldMap = worldMap
        newView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        return worldMap
    }
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: worldMapURL)
    }
    @IBAction func loadButtonAction(_ sender: Any) {
        debugLabel.text = worldMapURL.absoluteString
        print(debugLabel.text)
        debugLabel.text = String(info.count)
    }
    
    func loadARView(data: Data, i: Int){
        let worldMap: ARWorldMap = {
            guard let data = try? data
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
    
    @IBAction func resetButton(_sender: Any) {
        newView.session.run(defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "historySegue" {
            if let dest = segue.destination as? HistoryTableViewController {
                dest.entries = self.entries
                dest.historyDelegate = self
            }
        }
    }
}

extension ViewController : HistoryTableViewControllerDelegate{
    func selectEntry(entry: ZooLookup, index: Int) {
        loadARView(data: entry.data, i: index)
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors{
            if let anchorName = anchor.name, anchorName == "Cube"{
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}
