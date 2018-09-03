//
//  AddMemberViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/12/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import SkyFloatingLabelTextField
import TBEmptyDataSet

class AddMemberViewController: UIViewController {

    @IBOutlet weak var nameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var heightTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var sideTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addToLineupButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var newMemberDelegate: NewMemberDelegate?
    var crewMembers = [CrewMember]()
    var filteredMembers = [CrewMember]()
    var selectedMember: CrewMember?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Member", style: .plain, target: self, action: #selector(createNewMember))
        style(button: addToLineupButton)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDataSource = self
        tableView.emptyDataSetDelegate = self
        searchBar.delegate = self
        fetchCoreData()
    }
    
    @objc func createNewMember() {
        //Go to "Create New Member"
        if let memberEditorVC = storyboard?.instantiateViewController(withIdentifier: "memberEditor") as? MemberEditorViewController {
            memberEditorVC.newMemberDelegate = self
            memberEditorVC.returnToAddMember = true
            navigationController?.pushViewController(memberEditorVC, animated: true)
        }   
    }

    @IBAction func addToLineupAction(_ sender: Any) {
        guard let member = selectedMember else { showError(message: "Please select a crew member!"); return }
        newMemberDelegate?.newMember(member: member)
        navigationController?.popViewController(animated: true)
    }
    
    fileprivate func fetchCoreData() {
        do {
            let memberData = try managedContext.fetch(NSFetchRequest<CrewMember>(entityName: "CrewMember"))
            crewMembers.removeAll()
            for member in memberData {
                if member.cleared {
                    crewMembers.append(member)
                }
            }
            filteredMembers = crewMembers
            tableView.reloadData()
        } catch {
            print("Fetch Error: \(error)")
        }
    }
    
    
}

extension AddMemberViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell", for: indexPath) as? CrewMemberTableViewCell else { fatalError() }
        let member = filteredMembers[indexPath.row]
        cell.member = member
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let member = filteredMembers[indexPath.row]
        nameTextField.text = "\(member.firstName ?? "Error") \(member.lastName ?? "Error")"
        sideTextField.text = member.side ?? "Error"
        heightTextField.text = member.height ?? "Error"
        notesField.text = member.notes
        selectedMember = member
    }
    
    
}

extension AddMemberViewController: NewMemberDelegate {
    func newMember(member: CrewMember) {
        fetchCoreData()
        searchBar.text = ""
        tableView.reloadData()
        selectedMember = member
        if let selectedIndex = crewMembers.firstIndex(of: member) {
            let selectedIndexPath = IndexPath(row: selectedIndex, section: 0)
            tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .middle)
            tableView.delegate?.tableView!(tableView, didSelectRowAt: selectedIndexPath)
        }
        
    }
}

extension AddMemberViewController: TBEmptyDataSetDelegate, TBEmptyDataSetDataSource {
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "No Crew Members.")
    }
    
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "Tap 'New Member' to add new members.")
        
    }
    
    func emptyDataSetWillAppear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
    
    func emptyDataSetWillDisappear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
}

extension AddMemberViewController: UISearchBarDelegate {
    
    fileprivate func updateSearchResults(from searchBar: UISearchBar) {
        guard let searchText = searchBar.text?.lowercased() else {
            filteredMembers = crewMembers
            tableView.reloadData()
            return
        }
        if !searchText.isEmpty {
            filteredMembers = crewMembers.filter { ($0.searchText?.lowercased().contains(searchText))! }
            filteredMembers.forEach { (member) in
                print(member.searchText)
            }
        } else {
            filteredMembers = crewMembers
        }
        tableView.reloadData()
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
