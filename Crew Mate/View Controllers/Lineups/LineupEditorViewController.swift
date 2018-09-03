//
//  LineupEditorViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/11/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import SkyFloatingLabelTextField
import TBEmptyDataSet
import XLActionController
import MessageUI
import SwiftyJSON

class LineupEditorViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var oarTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var boatTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet weak var selectOarButton: UIButton!
    @IBOutlet weak var selectBoatButton: UIButton!
    @IBOutlet weak var reorderButton: UIButton!
    @IBOutlet weak var nameField: SkyFloatingLabelTextField!
    @IBOutlet weak var shareButton: UIButton!
    
    let lineupSections = ["Row 9", "Row 8", "Row 7", "Row 6", "Row 5", "Row 4", "Row 3", "Row 2", "Row 1",] //Coxswain - Last rower in line
    var currentLineup: Lineup?
    var editingLineup = false
    var crewMembers = [CrewMember]()
    var showBoatEquipment = false
    var currentBoat: Equipment?
    var currentOar: Equipment?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        style(button: saveButton)
        style(button: reorderButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewMember))
        setupTableView()
        
        toggleShareButton()
        if editingLineup {
            if let lineup = currentLineup {
                setEquipment(from: lineup)
                fetchLineupData()
            }
        }
        
    }
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEditing(false, animated: false)
        tableView.emptyDataSetDataSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    fileprivate func canShare() -> Bool {
        return MFMailComposeViewController.canSendMail() && MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments()
    }
    
    @IBAction func showShareSheet() {
        exportLineup(from: currentLineup!)
        if canShare() {
            guard let lineup = currentLineup else { return }
            guard let exportData = exportLineup(from: lineup) else { return }
            let fileName = "\((lineup.name)!)_lineup.cml"
            let actionSheet = TweetbotActionController()

            
            
            if MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments() {
                actionSheet.addAction(Action("Share via Text Message", style: .default, handler: { action in
                    //UIApplication.shared.open(URL(string: "sms:")!, options: [:], completionHandler: nil)
                    let composeVC = MFMessageComposeViewController()
                    composeVC.messageComposeDelegate = self
                    composeVC.addAttachmentData(exportData, typeIdentifier: "cml", filename: fileName)
                    self.present(composeVC, animated: true, completion: nil)
                    
                }))
            }
            if MFMailComposeViewController.canSendMail() {
                actionSheet.addAction(Action("Share via Email", style: .default, handler: { action in
                    let mailVC = MFMailComposeViewController()
                    mailVC.mailComposeDelegate = self
                    mailVC.addAttachmentData(exportData, mimeType: "cml", fileName: fileName)
                    self.present(mailVC, animated: true, completion: nil)
                }))
            }
            actionSheet.addSection(Section())
            actionSheet.addAction(Action("Cancel", style: .cancel, handler: nil))
            
            present(actionSheet, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.alertPopup(title: "Error", message: "No Sharing Available.", buttonTitle: "Ok")
            }
        }
    }
    
    fileprivate func exportLineup(from lineup: Lineup) -> Data? {
        var members = [JSON]() //JSON Variable for holding json member data
        for member in crewMembers {
            //Convert Members Image Data to Base54 String
            let image: String = {
                //Compare Current Image to Saved Image - If Image matches "noUserImage" do not save (to reduce export file size)
                if let imageData = member.picture as Data? {
                    if let newImage = UIImage(data: imageData as Data) {
                        if !(newImage.isEqual(UIImage(named: "noUserImage"))) {
                            return convertImageToBase64(image: newImage)
                        }
                    }
                }
                return ""
            }()
            
            //Create JSON object for each member in lineup
            let memberData: JSON = [
                             "cleared"   : member.cleared,
                             "firstName" : member.firstName ?? "",
                             "lastName"  : member.lastName ?? "",
                             "searchText": member.searchText ?? "",
                             "height"    : member.height ?? "",
                             "id"        : member.id ?? "",
                             "notes"     : member.notes ?? "",
                             "picture"   : image,
                             "side"      : member.side ?? "",
                             "time2k"    : member.time2k ?? [],
                             "time5k"    : member.time5k ?? [],
                             "time6k"    : member.time6k ?? [] ]
            
            members.append(memberData)
        }
        
        let boatJson = createEquipmentJson(from: currentBoat)
        let oarJson = createEquipmentJson(from: currentOar)
        let dateStamp = lineup.createdAt?.timeIntervalSince1970
        
        //Create JSON object for lineup
        let lineupData: JSON = [ "boat"      : boatJson,
                                 "oar"       : oarJson,
                                 "id"        : lineup.id ?? "",
                                 "name"      : lineup.name ?? "",
                                 "createdAt" : dateStamp ?? 0,
                                 "row1"      : lineup.row1 ?? "",
                                 "row2"      : lineup.row2 ?? "",
                                 "row3"      : lineup.row3 ?? "",
                                 "row4"      : lineup.row4 ?? "",
                                 "row5"      : lineup.row5 ?? "",
                                 "row6"      : lineup.row6 ?? "",
                                 "row7"      : lineup.row7 ?? "",
                                 "row8"      : lineup.row8 ?? "",
                                 "row9"      : lineup.row9 ?? "",
                                 "members"   : members,
                                 "cmVersion"   : version()]
        
        //Convert JSON Lineup to Data for export
        do {
            let rawData = try lineupData.rawData()
            let filename = getDocumentsDirectory().appendingPathComponent("\((lineup.name)!)_lineup.cml")
            print(filename)
            try rawData.write(to: filename, options: .atomic)
            getDataFileSize(from: rawData)
            return rawData
        } catch {
            print("Raw Data Error: \(error)")
            return nil
        }
    }
    
    fileprivate func setEquipment(from lineup: Lineup) {
        if let boatId = lineup.boat {
            do {
                let boatPredicate = NSPredicate(format: "id == %@", boatId)
                let boatFetch = NSFetchRequest<Equipment>(entityName: "Equipment")
                boatFetch.predicate = boatPredicate
                let boatData = try managedContext.fetch(boatFetch)
                currentBoat = boatData.first
                boatTextField.text = currentBoat?.name ?? "Error"
            } catch {
                print("Error fetching boat: \(error)")
            }
        }
        
        if let oarId = lineup.oar {
            do {
                let oarPredicate = NSPredicate(format: "id == %@", oarId)
                let oarFetch = NSFetchRequest<Equipment>(entityName: "Equipment")
                oarFetch.predicate = oarPredicate
                let oarData = try managedContext.fetch(oarFetch)
                currentOar = oarData.first
                oarTextField.text = currentOar?.name ?? "Error"
            } catch {
                print("Error fetching oar: \(error)")
            }
        }
    }
    
    fileprivate func fetchLineupData() {
        guard let lineup = currentLineup else { return }
        nameField.text = lineup.name ?? "Data Error"
        var index = 1
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
                
            }
            index += 1
        }
        tableView.reloadData()
        
    }
    
    @IBAction func saveAction() {
        if editingLineup {
            saveEditedLineup()
        } else {
            saveNewLineup()
        }
    }
    
    fileprivate func saveNewLineup() {
        guard let name = nameField.text, !name.isEmpty else { showError(message: "Please enter a lineup name."); return }
        if crewMembers.count > 9 { showError(message: "It looks like you have too many crew members in this lineup."); return }
        if let newLineup = NSEntityDescription.insertNewObject(forEntityName: "Lineup", into: managedContext) as? Lineup {
            newLineup.name = name
            newLineup.createdAt = Date()
            newLineup.id = UUID().uuidString
            if let boat = currentBoat { newLineup.boat = boat.id }
            if let oar = currentOar { newLineup.oar = oar.id }
            var index = 1
            for crewMember in crewMembers {
                newLineup.setValue(crewMember.id, forKey: "row\(index)")
                print("Setting: \(String(describing: crewMember.firstName)) - \(String(describing: crewMember.id)) at Row \(index)")
                index += 1
            }
            
        } else {
            showError(message: "There was an error creating the data record.  Please try again.")
            return
        }
        saveCoreData()
        
    }
    
    fileprivate func saveEditedLineup() {
        guard let lineup = currentLineup else { return }
        guard let name = nameField.text, !name.isEmpty else { showError(message: "Please enter a lineup name."); return }
        if crewMembers.count > 9 { showError(message: "It looks like you have too many crew members in this lineup."); return }
        if let boat = currentBoat { lineup.boat = boat.id }
        if let oar = currentOar { lineup.oar = oar.id }
        
        lineup.name = name
        
        var index = 1
        for crewMember in crewMembers {
            lineup.setValue(crewMember.id, forKey: "row\(index)")
            print("Setting: \(String(describing: crewMember.firstName)) - \(String(describing: crewMember.id)) at Row \(index)")
            index += 1
        }
        saveCoreData()
        
    }
    
    fileprivate func saveCoreData() {
        do {
            try managedContext.save()
            navigationController?.popViewController(animated: true)
        } catch {
            print("Lineup Saveing Error: \(error)")
            showError(message: error.localizedDescription)
        }
    }
    
    @IBAction func reorderLineup() {
        if tableView.isEditing {
            reorderButton.setTitle("Reorder Lineup", for: .normal)
            tableView.setEditing(false, animated: true)
        } else {
            reorderButton.setTitle("Save Order", for: .normal)
            tableView.setEditing(true, animated: true)
        }
    }
    
    @objc func addNewMember() {
        performSegue(withIdentifier: "addNewMember", sender: self)
    }
    
    @IBAction func openEquipmentSelector(_ sender: UIButton) {
        if sender.tag == 1 { //Oar
            showBoatEquipment = false
            performSegue(withIdentifier: "equipmentSelector", sender: self)
        }
        
        if sender.tag == 2 { //Boat
            showBoatEquipment = true
            performSegue(withIdentifier: "equipmentSelector", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "equipmentSelector" {
            if let destinationVC = segue.destination as? EquipmentViewController {
                destinationVC.showBoatEquipment = showBoatEquipment
                destinationVC.equipmentDelegate = self
            }
        }
        
        if segue.identifier == "addNewMember" {
            if let destinationVC = segue.destination as? AddMemberViewController {
                destinationVC.newMemberDelegate = self
            }
        }
    }

    fileprivate func toggleShareButton() {
        if crewMembers.count > 0 {
            shareButton.isEnabled = true
        } else {
            shareButton.isEnabled = false
        }
    }

}

extension LineupEditorViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return crewMembers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "lineupPositionCell", for: indexPath) as? LineupPositionTableViewCell else { fatalError() }
        let crewMember = crewMembers[indexPath.section]
        cell.member = crewMember
        
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            crewMembers.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let member = crewMembers[sourceIndexPath.row]
        crewMembers.remove(at: sourceIndexPath.row)
        crewMembers.insert(member, at: destinationIndexPath.row)
    }
    
}

extension LineupEditorViewController: EquipmentDelegate {
    func equimentDelegate(boat: Equipment?, oar: Equipment?) {
        if let boat = boat {
            currentBoat = boat
            boatTextField.text = boat.name
        }
        
        if let oar = oar {
            currentOar = oar
            oarTextField.text = oar.name
        }
    }
}

extension LineupEditorViewController: NewMemberDelegate {
    func newMember(member: CrewMember) {
        crewMembers.append(member)
        tableView.reloadData()
        toggleShareButton()
    }
}

extension LineupEditorViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("User Canceled")
            controller.dismiss(animated: true, completion: nil)
        case .failed:
            print("Message Failed")
            controller.dismiss(animated: true, completion: nil)
        case .sent:
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

extension LineupEditorViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            print("User Canceled")
            controller.dismiss(animated: true, completion: nil)
        case .failed:
            if let err = error { showError(message: err.localizedDescription) }
        case .saved:
            print("User Saved")
            showError(message: "Email has been saved!")
        case .sent:
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

extension LineupEditorViewController: TBEmptyDataSetDelegate, TBEmptyDataSetDataSource {
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "No Members in Lineup")
    }
    
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "Tap the + button to add members to your lineup.")
    }
    
    func emptyDataSetWillAppear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
    
    func emptyDataSetWillDisappear(in scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
}
