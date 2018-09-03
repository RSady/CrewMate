//
//  HomeViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/11/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import TBEmptyDataSet
import SkyFloatingLabelTextField

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var crewMembersButton: UIButton!
    @IBOutlet weak var editLineupsButton: UIButton!
    @IBOutlet weak var nameField: SkyFloatingLabelTextField!
    @IBOutlet weak var editButton: UIButton!
    
    var selectedLineup: Lineup?
    var allLineups = [Lineup]()
    var crewMembers = [CrewMember]()
    let pickerView = UIPickerView()
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let lineupSections = ["Row 9", "Row 8", "Row 8", "Row 6", "Row 5", "Row 4", "Row 3", "Row 2", "Row 1",] //Coxswain - Last rower in line
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Crew Mate"
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetDataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        
        style(button: crewMembersButton)
        style(button: editLineupsButton)
        style(button: editButton)
        setupPickerView()
        
    }
    
    @IBAction func editLineupAction() {
        guard let lineup = selectedLineup else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let lineupEditor = storyboard.instantiateViewController(withIdentifier: "lineupEditor") as? LineupEditorViewController else { return }
        lineupEditor.currentLineup = lineup
        lineupEditor.editingLineup = true
        navigationController?.pushViewController(lineupEditor, animated: true)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        fetchLineups()
    }
    
    fileprivate func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        nameField.inputView = pickerView
        nameField.inputAccessoryView = addToolbarItems(buttonTitle: "Select", labelTitle: "Lineups")
        
    }
    
    fileprivate func fetchLineups() {
        do {
            allLineups.removeAll()
            let lineupData = try managedContext.fetch(NSFetchRequest<Lineup>(entityName: "Lineup"))
            for lineup in lineupData {
                allLineups.append(lineup)
            }
            pickerView.reloadAllComponents()
        } catch {
            
        }
    }
    
    fileprivate func setCurrentLineup(lineup: Lineup) {
        nameField.text = lineup.name ?? "Data Error"
        var index = 1
        crewMembers.removeAll()
        for _ in 1...9 {
            if let memberId = lineup.value(forKey: "row\(index)") as? String {
                //Get Member Based on MemberID
                let memberPredicate = NSPredicate(format: "id == %@", memberId as CVarArg)
                do {
                    let fetchRequest = NSFetchRequest<CrewMember>(entityName: "CrewMember")
                    fetchRequest.predicate = memberPredicate
                    let crewMember = try managedContext.fetch(fetchRequest)
                    if let member = crewMember.first {
                        self.crewMembers.append(member)
                    }
                } catch {
                    print("Member Fetch Error: \(error)")
                }
                print("Row \(index) Appended: \(memberId)")
            } else {
                print("No Member for Row \(index)")
            }
            
            index += 1
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func addToolbarItems(buttonTitle: String, labelTitle: String) -> UIToolbar {
        // Create Toolbar Items
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
        toolbar.barStyle = UIBarStyle.default
        toolbar.tintColor = UIColor.black
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.donePressed(sender:)))
        doneButton.title = buttonTitle
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width/3, height: 40))
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.text = labelTitle
        let labelButton = UIBarButtonItem(customView: label)
        toolbar.setItems([flexButton, flexButton, labelButton, flexButton, doneButton], animated: true)
        return toolbar
    }
    
    @objc func donePressed (sender: UIBarButtonItem) {
        if let lineup = selectedLineup {
            setCurrentLineup(lineup: lineup)
        }
        view.endEditing(true)
    }

}

extension HomeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allLineups.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return allLineups[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLineup = allLineups[row]
    }
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return crewMembers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "lineupPositionCell", for: indexPath) as? LineupPositionTableViewCell else { fatalError() }
        let crewMember = crewMembers[indexPath.section]
        cell.nameLabel.text = "\(crewMember.firstName ?? "Error") \(crewMember.lastName ?? "Error")"
        switch crewMember.side {
        case "Port":
            cell.portImage.image = UIImage(named: "oar")
            cell.starboardImage.image = nil
        case "Starboard":
            cell.starboardImage.image = UIImage(named: "oar")
            cell.portImage.image = nil
        case "All":
            cell.starboardImage.image = UIImage(named: "oar")
            cell.portImage.image = UIImage(named: "oar")
        default:
            break
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == crewMembers.count {
            return "Coxswain"
        } else {
            return lineupSections[section]
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .center
        }
    }
}

extension HomeViewController: TBEmptyDataSetDelegate, TBEmptyDataSetDataSource {
    
    func emptyDataSetWillAppear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
    
    func emptyDataSetWillDisappear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
    
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "No Lineup Selected")
    }
    
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "Select a lineup to quick view it.")
    }
    
}
