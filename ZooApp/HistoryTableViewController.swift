//
//  HistoryTableViewController.swift
//  ZooApp
//
//  Created by Ian O'Strander and Jaxon Goggins on 11/20/22.
//

import UIKit
import Foundation

protocol HistoryTableViewControllerDelegate{
    func selectEntry(entry: ZooLookup, index: Int)
    func deleteData(index:Int)
}

class HistoryTableViewController: UITableViewController{
    var entries : [ZooLookup] = []
    var historyDelegate: HistoryTableViewControllerDelegate?
    var tableViewData: [(sectionHeader: String, endtires: [ZooLookup])]?{
        didSet{
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let del = self.historyDelegate{
            del.selectEntry(entry: entries[indexPath.row], index: indexPath.row)
        }
        self.dismiss(animated: true)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! HistoryTableViewCell
        cell.cellContent?.text = entries[indexPath.row].name
        return cell
    }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle{
        return .delete
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete{
            tableView.beginUpdates()
            entries.remove(at: indexPath.row)
            if let del = self.historyDelegate{
                del.deleteData(index: indexPath.row)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
