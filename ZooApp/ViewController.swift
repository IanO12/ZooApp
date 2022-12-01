//
//  ViewController.swift
//  ZooApp
//
//  Created by Ian J. O'Strander on 11/16/22.
//

import UIKit
import RealityKit
import ARKit
class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    func pickerView(_pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return self.pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        <#code#>
    }
    
    
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var LoadWorld: UIButton!
    @IBOutlet weak var newView: ARView!
    @IBOutlet weak var animalPicker: UIPickerView!
    @IBOutlet weak var SaveWorld: UIButton!
    @IBOutlet weak var newAnimal: UIButton!
    var pickerData: [String] = [String]()
    var currentIndex = 0
    var entries : [ZooLookup] = []
    var info : [Data] = []
    var infoName : [String] = []
    var defualts = UserDefaults.standard
    //var chocieAnimal = ["alligator", "elephant", "gorilla", "jaguar", "kangaroo", "snake", "tiger", "zebra", "emu"]
    var animal = "gorilla"
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
        entries = []
        debugLabel.text = String(info.count)
    }
    
    @IBAction func pickAnimalAction(_sender: Any) {
        if animalPicker.isHidden{
            self.animalPicker.isHidden = false
            self.pickerData = ["alligator", "elephant", "gorilla", "jaguar", "kangaroo", "snake", "tiger", "zebra", "emu"]
            self.animalPicker.reloadAllComponents()
        }else{
            self.animalPicker.isHidden = true
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.animalPicker.isHidden = true
        self.animalPicker.delegate = self
        self.animalPicker.dataSource = self
        print(worldMapURL)
        if(defualts.array(forKey: "Maps") != nil && defualts.array(forKey:"Names") != nil){
            info = defualts.array(forKey:"Maps") as! [Data]
            infoName = defualts.array(forKey:"Names") as! [String]
            debugLabel.text = String(info.count)
            if info.count != infoName.count{
                print("ERROR DATA COUNT != NAME COUNT")
            }
            else if info.count < 1{
                print("LIST TOO SMALL")
            }else{
                for i in 0...info.count - 1{
                    print(i)
                    entries.append(ZooLookup(name:infoName[i], data: info[i]))
                }
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
            let anchor = ARAnchor(name: animal, transform: firstResult.worldTransform)
            print("ADDED ANCHOR")
            newView.session.add(anchor: anchor)
        } else{
            print("Object Placement Failed")
        }
    }
    @objc func hidePicker(sender: UIGestureRecognizer) {
        self.animalPicker.isHidden = true
    }
    
    func placeObject(named entityName: String, for anchor: ARAnchor){
        let url = URL(fileURLWithPath: Bundle.main.path(forResource:animal, ofType: "usdz")!)
        if let entity = try? Entity.load(contentsOf: url){
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
                //self.showAlert(title: "No Map", message: error!.localizedDescription); return
                print("No map")
                return
            }
             do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                 try data.write(to: self.worldMapURL, options: [.atomic])
                 self.info.append(data)
                 self.infoName.append(self.name)
                 self.defualts.set(self.info, forKey: "Maps")
                 self.defualts.set(self.infoName, forKey: "Names")
                 self.entries.append(ZooLookup(name:self.name, data: data))
                 self.debugLabel.text = String(self.info.count)
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
        let configuration = self.defaultConfiguration
        configuration.initialWorldMap = worldMap
        newView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        return worldMap
    }
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: worldMapURL)
    }
    @IBAction func loadButtonAction(_ sender: Any) {

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
    func deleteData(index: Int){
        info.remove(at: index)
        infoName.remove(at: index)
        entries.remove(at:index)
        defualts.set(self.info, forKey: "Maps")
        defualts.set(self.infoName, forKey: "Names")
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
