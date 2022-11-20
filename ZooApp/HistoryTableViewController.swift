//
//  HistoryTableViewController.swift
//  ZooApp
//
//  Created by Krin Beach on 11/20/22.
//

import UIKit
import Foundation

protocol HistoryTableViewControllerDelegate{
    func selectEntry(entry: ZooLookup)
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
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! HistoryTableViewCell

        cell.cellContent?.text = "HELLLOO"
        
        return cell
    }
}
