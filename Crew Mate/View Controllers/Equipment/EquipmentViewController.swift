//
//  EquipmentViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/12/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import TBEmptyDataSet

class EquipmentViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    
    var showBoatEquipment = false
    var editingEquipment = false
    var selectedEquipment: Equipment?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var equipmentDelegate: EquipmentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewEquipment))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDataSource = self
        tableView.emptyDataSetDelegate = self
        style(button: editButton)
        style(button: selectButton)
        
        if showBoatEquipment {
            title = "Boats"
        } else {
            title = "Oars"
        }
        fetchCoreData()
        
        //Disable Edit Button Because No Selection Is Made
        enableEditButton(false)
        
    }
    
    fileprivate func enableEditButton(_ enabled: Bool) {
        if enabled {
            editButton.isEnabled = true
            editButton.backgroundColor = aquaBlue
        } else {
            editButton.isEnabled = false
            editButton.backgroundColor = disabledBlue
        }
    }
    
    fileprivate func fetchCoreData() {
        let equipmentType: String = { if showBoatEquipment { return "boat" } else { return "oar" } }()
        do {
            print("Fetching \(equipmentType)s")
            let predicate = NSPredicate(format: "type == %@", equipmentType)
            fetchedResultsController.fetchRequest.predicate = predicate
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("Error Fetching Equipment: \(error.localizedDescription)")
        }
    }

    @objc func addNewEquipment() {
        editingEquipment = false
        performSegue(withIdentifier: "equipmentEditor", sender: self)
    }
    
    @IBAction func editEquipment() {
        guard let _ = selectedEquipment else { showError(message: "No Equipment Selected!"); return }
        editingEquipment = true
        performSegue(withIdentifier: "equipmentEditor", sender: self)
    }
    
    @IBAction func selectAction() {
        let equipmentType: String = { if showBoatEquipment { return "a boat" } else { return "an oar" } }()
        guard let equipment = selectedEquipment else { showError(message: "Please select \(equipmentType)!"); return }
        if equipment.type == "oar" {
            equipmentDelegate?.equimentDelegate(boat: nil, oar: equipment)
        } else {
            equipmentDelegate?.equimentDelegate(boat: equipment, oar: nil)
        }
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "equipmentEditor" {
            if let destinationVC = segue.destination as? EquipmentEditorViewController {
                destinationVC.currentEquipment = selectedEquipment
                destinationVC.equipmentIsBoat = showBoatEquipment
                destinationVC.editingEquipment = editingEquipment
            }
        }
    }

    
    lazy var fetchedResultsController: NSFetchedResultsController<Equipment> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Equipment> = Equipment.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()

}


extension EquipmentViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "equipmentCell", for: indexPath) as? EquipmentTableViewCell else { fatalError() }
        guard let equipment = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            fatalError("Data Error")
        }
        cell.equipment = equipment        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let equipment = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            fatalError("Data Error")
        }
        
        selectedEquipment = equipment
        enableEditButton(true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "equipmentCell", for: indexPath) as? EquipmentTableViewCell else { fatalError() }
        cell.checkBox.image = nil
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let equipment = fetchedResultsController.object(at: indexPath)
            let alertView = UIAlertController(title: "Delete \(equipment.name ?? "")?", message: "This action can't be undone!", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                equipment.managedObjectContext?.delete(equipment)
                do {
                    try self.managedContext.save()
                    print("Save Success on Delete")
                } catch {
                    print("Error Saving on Delete")
                }
            }))
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alertView, animated: true, completion: nil)
        }
    }
    
}


extension EquipmentViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        tableView.reloadData()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .left)
            }
            break
        case .update:
            //            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? ShoeTableViewCell {
            //                configure(cell, at: indexPath)
            //            }
            break
        default:
            print("...")
        }
    }
    
    
}

extension EquipmentViewController: TBEmptyDataSetDelegate, TBEmptyDataSetDataSource {
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        switch showBoatEquipment {
        case true:
            return NSAttributedString(string: "No Boats")
        case false:
            return NSAttributedString(string: "No Oars")
        }
        
    }
    
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        switch showBoatEquipment {
        case true:
            return NSAttributedString(string: "Tap the + button to add new boats.")
        case false:
            return NSAttributedString(string: "Tap the + button to add new oars.")
        }
        
    }
    
    func emptyDataSetWillAppear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
    
    func emptyDataSetWillDisappear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
}




