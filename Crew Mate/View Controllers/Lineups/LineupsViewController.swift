//
//  LineupsViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/11/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import TBEmptyDataSet

class LineupsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var editingLineup = false
    var selectedLineup: Lineup?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "lineupCell")
        tableView.emptyDataSetDataSource = self
        tableView.emptyDataSetDelegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewLineup))
        
        fetchCoreData()
    }

    @objc func addNewLineup() {
        editingLineup = false
        performSegue(withIdentifier: "lineupEditor", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "lineupEditor" {
            if let destinationVC = segue.destination as? LineupEditorViewController {
                destinationVC.editingLineup = editingLineup
                if editingLineup {
                    destinationVC.currentLineup = selectedLineup
                }
            }
        }
    }
    
    fileprivate func fetchCoreData() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error Fetching Lineups: \(error.localizedDescription)")
        }
    }

    lazy var fetchedResultsController: NSFetchedResultsController<Lineup> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Lineup> = Lineup.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
}

extension LineupsViewController: NSFetchedResultsControllerDelegate {
    
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
        default:
            print("...")
        }
    }
    
}

extension LineupsViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "lineupCell", for: indexPath)
        guard let lineup = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            fatalError("Data Error")
        }
        cell.textLabel?.text = lineup.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Segue to Member Editor
        selectedLineup = fetchedResultsController.fetchedObjects?[indexPath.row]
        if let _ = selectedLineup {
            editingLineup = true
            performSegue(withIdentifier: "lineupEditor", sender: self)
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let lineup = fetchedResultsController.object(at: indexPath)
            lineup.managedObjectContext?.delete(lineup)
            
            do {
                try managedContext.save()
                print("Save Success on Delete")
            } catch {
                print("Error Saving on Delete")
            }
        }
        
    }
    
    
}

extension LineupsViewController: TBEmptyDataSetDelegate, TBEmptyDataSetDataSource {
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "No Lineups")
    }
    
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "Tap the + button to create a new lineup.")
    }
    
    func emptyDataSetWillAppear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
    
    func emptyDataSetWillDisappear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
}

extension LineupsViewController: UISearchBarDelegate {
    
    fileprivate func updateSearchResults(from searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            fetchedResultsController.fetchRequest.predicate = nil
            tableView.reloadData()
            return
        }
        if !searchText.isEmpty {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "name contains[c] %@", searchBar.text!)
        } else {
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
