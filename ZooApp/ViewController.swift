//
//  ViewController.swift
//  ZooApp
//
//  Created by Ian J. O'Strander and Jaxon Goggins on 11/16/22.
//

import UIKit
import RealityKit
import ARKit
class ViewController: UIViewController {
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var resetWorld: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var loadWorld: UIButton!
    @IBOutlet weak var saveWorld: UIButton!
    @IBOutlet weak var newAnimal: UIButton!
    @IBOutlet weak var viewWorld: UIButton!
    @IBOutlet weak var newView: ARView!
    @IBOutlet weak var animalPicker: UIPickerView!
    
    var pickerData: [String] = [String]()
    var currentIndex = 0
    var entries : [ZooLookup] = []
    var mapData : [Data] = []
    var nameData : [String] = []
    var defualts = UserDefaults.standard
    
    var editMode : Bool = true
    var animal = "alligator"

    var name: String = ""
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    @IBAction func viewWorldAction(_sender: Any) {
        saveWorld.isHidden = editMode
        animalPicker.isHidden = editMode
        resetWorld.isHidden = editMode
        loadWorld.isHidden = editMode
        
        editMode = !editMode
        if editMode{
            viewWorld.setTitle("View", for: .normal)
        }else{
            viewWorld.setTitle("Edit", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animalPicker.delegate = self
        animalPicker.dataSource = self
        viewWorld.isHidden = false
        debugLabel.isHidden = true
        if(defualts.array(forKey: "Maps") != nil && defualts.array(forKey:"Names") != nil){
            mapData = defualts.array(forKey:"Maps") as! [Data]
            nameData = defualts.array(forKey:"Names") as! [String]
            debugLabel.text = String("info count \(mapData.count) infoName count \(nameData.count)")
            if mapData.count != nameData.count{
                print("ERROR DATA COUNT != NAME COUNT")
            }
            else if mapData.count < 1{
                print("LIST TOO SMALL")
            }else{
                for i in 0...mapData.count - 1{
                    print(i)
                    entries.append(ZooLookup(name:nameData[i], data: mapData[i]))
                }
            }
        }
        pickerData = ["alligator", "elephant", "gorilla", "jaguar", "kangaroo", "snake", "tiger", "zebra", "emu"]
        animalPicker.backgroundColor = .clear
        
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
        print(location)
        let results = newView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first{
            let anchor = ARAnchor(name: animal, transform: firstResult.worldTransform)
//            print("ADDED ANCHOR")
            newView.session.add(anchor: anchor)
        } else{
            print("Object Placement Failed")
        }
    }
    
    func placeObject(named entityName: String, for anchor: ARAnchor){
        let url = URL(fileURLWithPath: Bundle.main.path(forResource:entityName, ofType: "usdz")!)
        if let entity = try? Entity.loadModel(contentsOf: url){
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(entity)
            newView.scene.addAnchor(anchorEntity)
            entity.playAnimation(entity.availableAnimations[0].repeat())
        }else{
            print("Couldn't find model")
        }
        
    }
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
                print("No map")
                return
            }
             do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                 var hasEntry = false
                 if self.entries.count > 0{
                     for i in 0...self.entries.count - 1{
                         if self.entries[i].name == self.name{
                             self.entries[i].data = data
                             self.mapData[i] = data
                             self.nameData[i] = self.name
                             hasEntry = true
                         }
                     }
                 }
                 if !hasEntry{
                     self.entries.append(ZooLookup(name:self.name, data: data))
                     self.mapData.append(data)
                     self.nameData.append(self.name)
                 }
                 self.defualts.set(self.mapData, forKey: "Maps")
                 self.defualts.set(self.nameData, forKey: "Names")
                 self.debugLabel.text = String(self.mapData.count)
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    func loadARView(data: Data, i: Int){
        newView.scene.anchors.removeAll()
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
    func deleteData(index: Int){
        mapData.remove(at: index)
        nameData.remove(at: index)
        entries.remove(at:index)
        defualts.set(self.mapData, forKey: "Maps")
        defualts.set(self.nameData, forKey: "Names")
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("anchors = \(anchors.count)")
        for anchor in anchors{
            if let anchorName = anchor.name{
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return self.pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.animal = self.pickerData[row]
    }
}
