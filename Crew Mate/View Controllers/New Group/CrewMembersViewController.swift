//
//  CrewMembersViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/11/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import TBEmptyDataSet

class CrewMembersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var editingMember = false
    var crewMembers = [CrewMember]()
    var selectedMember: CrewMember?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetDataSource = self
                
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMember))
        
        fetchCoreData()
    }
    
    @objc func addMember() {
        editingMember = false
        performSegue(withIdentifier: "memberEditor", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "memberEditor" {
            if let destinationVC = segue.destination as? MemberEditorViewController {
                destinationVC.editingMember = editingMember
                if editingMember {
                    if let member = selectedMember {
                        destinationVC.currentMember = member
                    }
                }
            }
        }
    }

    fileprivate func fetchCoreData() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error Fetching Members: \(error.localizedDescription)")
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<CrewMember> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<CrewMember> = CrewMember.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
}

extension CrewMembersViewController: NSFetchedResultsControllerDelegate {
    
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

extension CrewMembersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
            
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "memberListCell", for: indexPath) as? MemberListTableViewCell else { fatalError() }
        guard let crewMember = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            fatalError("Data Error")
        }
        cell.crewMember = crewMember
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Segue to Member Editor
        selectedMember = fetchedResultsController.fetchedObjects?[indexPath.row]
        if let _ = selectedMember {
            editingMember = true
            performSegue(withIdentifier: "memberEditor", sender: self)
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            //Confirm Delete
            let alertView = UIAlertController(title: "Are you sure?", message: "This member will no longer appear in any saved lineups.", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                let crewMember = self.fetchedResultsController.object(at: indexPath)
                crewMember.managedObjectContext?.delete(crewMember)
                
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

extension CrewMembersViewController: TBEmptyDataSetDelegate, TBEmptyDataSetDataSource {
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "No Crew Members")
    }
    
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "Tap the + button to add new members.")
    }
    
    func emptyDataSetWillAppear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
    
    func emptyDataSetWillDisappear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
}

extension CrewMembersViewController {
    
}

extension CrewMembersViewController: UISearchBarDelegate {
    
    fileprivate func updateSearchResults(from searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            fetchedResultsController.fetchRequest.predicate = nil
            tableView.reloadData()
            return
        }
        if !searchText.isEmpty {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "searchText contains[c] %@", searchBar.text!)
        } else {
            print("text is empty: \(searchText)")
            fetchedResultsController.fetchRequest.predicate = nil
        }
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch. \(error)")
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        updateSearchResults(from: searchBar)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        updateSearchResults(from: searchBar)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateSearchResults(from: searchBar)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults(from: searchBar)
    }
}
