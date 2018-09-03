//
//  MemberEditorViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/11/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import CoreData
import AVFoundation
import MobileCoreServices
import XLActionController

class MemberEditorViewController: UIViewController {

    @IBOutlet weak var firstNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var lastNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var heightField: SkyFloatingLabelTextField!
    @IBOutlet weak var sideField: SkyFloatingLabelTextField!
    @IBOutlet weak var notesTextField: UITextView!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var twoKTimeField: SkyFloatingLabelTextField!
    @IBOutlet weak var fiveKTimeField: SkyFloatingLabelTextField!
    @IBOutlet weak var sixKTimeField: SkyFloatingLabelTextField!
    @IBOutlet weak var clearedSwitch: UISwitch!
    
    let imagePicker = UIImagePickerController()
    let heightPicker = UIPickerView()
    let sidePicker = UIPickerView()
    let sides = ["", "Port", "Starboard", "All"]
    let heightData = [[4, 5, 6, 7,], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,]]
    let timeData = [Array(0...99), Array(0...99), Array(0...99)]
    var editingMember = false
    var currentMember: CrewMember?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let twoKPicker = UIPickerView()
    let fiveKPicker = UIPickerView()
    let sixKPicker = UIPickerView()
    var returnToAddMember = false
    var newMemberDelegate: NewMemberDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        setupPickerViews()
        
        style(button: saveButton)
        style(button: takePictureButton)
        
        clearedSwitch.setOn(false, animated: false)
        
        if editingMember {
            title = "Edit Member"
            if let crewMember = currentMember { populateData(from: crewMember) }
        } else {
            title = "Create New Member"
            imageView.image = UIImage(named: "noUserImage")
        }
        styleImageView(imageView)
        styleNotesField()
    }
    
    fileprivate func styleNotesField() {
        notesTextField.layer.cornerRadius = 10
        notesTextField.layer.borderColor = UIColor.black.cgColor
        notesTextField.layer.borderWidth = 1
        notesTextField.clipsToBounds = true
        notesTextField.layer.masksToBounds = true
    }
    
    fileprivate func styleImageView(_ imageView: UIImageView) {
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.frame.width / 2
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = true
    }
    
    fileprivate func populateData(from member: CrewMember) {
        firstNameField.text = member.firstName
        lastNameField.text = member.lastName
        heightField.text = member.height
        sideField.text = member.side
        notesTextField.text = member.notes
        
        //Set Cleared Switch
        if member.cleared {
            clearedSwitch.setOn(true, animated: true)
        } else {
            clearedSwitch.setOn(false, animated: true)
        }
        
        //Times
        if let twoKTime = member.time2k { twoKTimeField.text = formatTimeForDisplay(time: twoKTime) }
        if let fiveKTime = member.time5k { fiveKTimeField.text = formatTimeForDisplay(time: fiveKTime) }
        if let sixKTime = member.time6k { sixKTimeField.text = formatTimeForDisplay(time: sixKTime) }
        
        //Get Users Image
        if let imageData = member.picture as NSData? {
            let newImage = UIImage(data: imageData as Data)
            imageView.image = newImage
        } else {
            imageView.image = UIImage(named: "noUserImage")
        }
    }
    
    fileprivate func createMemberRecord(firstName: String, lastName: String, height: String, rowingSide: String) -> CrewMember? {
        if let newMember = NSEntityDescription.insertNewObject(forEntityName: "CrewMember", into: managedContext) as? CrewMember {
            newMember.firstName = firstName
            newMember.lastName = lastName
            newMember.height = height
            newMember.side = rowingSide
            newMember.notes = notesTextField.text
            newMember.id = UUID().uuidString
            newMember.searchText = "\(firstName) \(lastName)"
            
            if let twoKTime = twoKTimeField.text {
                newMember.time2k = formatTimeForSaving(time: twoKTime)
            }
            if let fiveKTime = fiveKTimeField.text {
                newMember.time5k = formatTimeForSaving(time: fiveKTime)
            }
            if let sixKTime = sixKTimeField.text {
                newMember.time6k = formatTimeForSaving(time: sixKTime)
            }
            
            //Convert Image to Data for Saving
            if let image = imageView.image {
                if !image.isEqual(UIImage(named: "noUserImage")) {
                    if let imageData: Data = image.jpegData(compressionQuality: 1) {
                        newMember.picture = imageData
                    }
                }
            }
            
            //Set Cleared via Switch
            if clearedSwitch.isOn {
                newMember.cleared = true
            } else {
                newMember.cleared = false
            }
            return newMember
        }
        return nil
    }
    
    fileprivate func createAndSaveNewMember() {
        //Creates and saves New CrewMember object from data fields
        guard let firstName = firstNameField.text, !firstName.isEmpty else { showError(message: "Please enter a first name."); return }
        guard let lastName = lastNameField.text, !lastName.isEmpty else { showError(message: "Please enter a last name."); return }
        guard let height = heightField.text, !height.isEmpty else { showError(message: "Please select a height."); return }
        guard let rowingSide = sideField.text, !rowingSide.isEmpty else { showError(message: "Please select a rowing side."); return }
        
        //Check first & last name against existing members and alert if already exists
        ifNameIsValid(firstName: firstName, lastName: lastName) { (success) in
            var newMember: CrewMember?
            if success {
                newMember = self.createMemberRecord(firstName: firstName, lastName: lastName, height: height, rowingSide: rowingSide)
                self.saveCoreData(with: newMember)
            } else {
                let alertController = UIAlertController(title: "Member Exists", message: "The first and last name of the newly created crew member matches an existing record.  Are you sure you want to create a new record?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Create New Member", style: .default, handler: { (_) in
                    newMember = self.createMemberRecord(firstName: firstName, lastName: lastName, height: height, rowingSide: rowingSide)
                    self.saveCoreData(with: newMember)
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        
    }
    
    fileprivate func ifNameIsValid(firstName: String, lastName: String, completion: @escaping (Bool) -> Void) {
            do {
                let predicate = NSPredicate(format: "searchText == %@", "searchText")
                let fetchRequest = NSFetchRequest<CrewMember>(entityName: "CrewMember")
                fetchRequest.predicate = predicate
                let memberData = try managedContext.fetch(NSFetchRequest<CrewMember>(entityName: "CrewMember"))
                for mem in memberData {
                    if mem.searchText == "\(firstName) \(lastName)" {
                        completion(false)
                        return
                    }
                }
                completion(true)
            } catch {
                print(error)
                completion(false)
            }
    }
    
    fileprivate func saveCoreData(with member: CrewMember?) {
        //Pass Newly Created Member to AddMemberViewController
        if returnToAddMember {
            if let member = member { //Unwrap member object
                newMemberDelegate?.newMember(member: member)
            }
        }
        do {
            try managedContext.save()
            //Pop View Controller if Save Successful
            navigationController?.popViewController(animated: true)
        } catch {
            print("Save Error: \(error)")
            showError(message: error.localizedDescription)
        }
    }
    
    fileprivate func saveCurrentMember() {
        //Saving Member That Was Edited
        
        //Data Validation
        guard let member = currentMember else { return }
        guard let firstName = firstNameField.text, !firstName.isEmpty else { showError(message: "Please enter a first name."); return }
        guard let lastName = lastNameField.text, !lastName.isEmpty else { showError(message: "Please enter a last name."); return }
        guard let height = heightField.text, !height.isEmpty else { showError(message: "Please select a height."); return }
        guard let rowingSide = sideField.text, !rowingSide.isEmpty else { showError(message: "Please select a rowing side."); return }
        
        
        //Check for Set Times and Save if Entered
        if let twoKTime = twoKTimeField.text {
            member.time2k = formatTimeForSaving(time: twoKTime)
        }
        if let fiveKTime = fiveKTimeField.text {
            member.time5k = formatTimeForSaving(time: fiveKTime)
        }
        if let sixKTime = sixKTimeField.text {
            member.time6k = formatTimeForSaving(time: sixKTime)
        }
        
        //Set Data
        member.firstName = firstName
        member.lastName = lastName
        member.height = height
        member.side = rowingSide
        member.notes = notesTextField.text
        
        //Convert Image to Data for Saving
        if let image = imageView.image {
            //If Image is default do not save
            if !image.isEqual(UIImage(named: "noUserImage")) {
                if let imageData: Data = image.jpegData(compressionQuality: 1) {
                    member.picture = imageData
                }
            }
        }
        
        //Set Cleared via Switch
        if clearedSwitch.isOn {
            member.cleared = true
        } else {
            member.cleared = false
        }
        saveCoreData(with: nil)
        
    }

    @IBAction func takePictureAction(_ sender: UIButton) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                DispatchQueue.main.async {
                    self.selectImage()
                }
                return
            } else {
                DispatchQueue.main.async {
                    self.alertPopup(title: "Please Allow Camera Services", message: "Navigate to Settings -> Privacy -> Camera, and make sure 'CrewMate' is enabled", buttonTitle: "Ok")
                }
            }
        }
    }
    
    fileprivate func selectImage() {
        let actionSheet = TweetbotActionController()
        actionSheet.addAction(Action("Take New Picture", style: .default, handler: { action in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: {
                    
                })
            } else {
                DispatchQueue.main.async {
                    self.showError(message: "No detected on device.")
                }
            }
        }))
        
        actionSheet.addAction(Action("Select Existing Picture", style: .default, handler: { action in
            
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: {
                
            })
        }))
        
        actionSheet.addAction(Action("Reset to Default", style: .default, handler: { action in
            
            self.imageView.image = UIImage(named: "noUserImage")
            
        }))
        
        actionSheet.addSection(Section())
        actionSheet.addAction(Action("Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        if editingMember {
            //Editing Member...Save Current Data
            saveCurrentMember()
        } else {
            //Creating New Member
            createAndSaveNewMember()
        }
    }
    
    fileprivate func setTimePicker(picker: UIPickerView, tag: Int) {
        picker.delegate = self
        picker.dataSource = self
        picker.tag = tag
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
        view.endEditing(true)
    }
    
}

extension MemberEditorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    ///Set Text Label Time After Selecting PickerView Data
    func updateDisplayFor(textLabel: SkyFloatingLabelTextField, from picker: UIPickerView) {
        let min = timeData[0][picker.selectedRow(inComponent: 0)]
        let sec = timeData[1][picker.selectedRow(inComponent: 1)]
        let th = timeData[2][picker.selectedRow(inComponent: 2)]
        textLabel.text = "\(min):\(sec).\(th)"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView.tag == 1 {
            return 2
        }
        if pickerView.tag == 2 {
            return 1
        }
        
        if pickerView.tag == 4 || pickerView.tag == 5 || pickerView.tag == 6 {
            return 3
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            if component == 0 {
                return heightData[0].count
            } else if component == 1 {
                return heightData[1].count
            }
        }
        if pickerView.tag == 2 {
            return sides.count
        }
        
        if pickerView.tag == 4 || pickerView.tag == 5 || pickerView.tag == 6 {
            if component == 0 {
                return timeData[0].count
            } else if component == 1 {
                return timeData[1].count
            } else if component == 2 {
                return timeData[2].count
            }
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 { //Height
            if component == 0 {
                return "\(heightData[0][row])"
            } else if component == 1 {
                return "\(heightData[1][row])"
            }
        }
        if pickerView.tag == 2 { //Sides
            return sides[row]
        }
        
        if pickerView.tag == 4 || pickerView.tag == 5 || pickerView.tag == 6 { //Times
            if component == 0 { //Minute
                return "\(timeData[0][row])"
            } else if component == 1 { //Seconds
                return "\(timeData[1][row])"
            } else if component == 2 { //Thousands Second
                return "\(timeData[2][row])"
            }
        }
        
        return nil
    }
    
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 { //Height
            let feet = heightData[0][pickerView.selectedRow(inComponent: 0)]
            let inches = heightData[1][pickerView.selectedRow(inComponent: 1)]
            heightField.text = "\(feet) ft \(inches) in"
        }
        if pickerView.tag == 2 { //Sides
            sideField.text = sides[row]
        }
        
        if pickerView.tag == 4 { //4K Time
            updateDisplayFor(textLabel: twoKTimeField, from: pickerView)
        }
        
        if pickerView.tag == 5 { //5K Time
            updateDisplayFor(textLabel: fiveKTimeField, from: pickerView)
        }
        
        if pickerView.tag == 6 { //6K Time
            updateDisplayFor(textLabel: sixKTimeField, from: pickerView)
        }
    }
}

extension MemberEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension MemberEditorViewController { //Helper Functions
    
    fileprivate func formatTimeForSaving(time: String?) -> [Int]? {
        guard let timeStr = time, time != "" else { return nil }
        //mm:ss.th
        let split1 = timeStr.split(separator: ":")
        let split2 = split1[1].split(separator: ".")
        let min = split1[0]
        let sec = split2[0]
        let th = split2[1]
        
        return [Int(min)!, Int(sec)!, Int(th)!]
    }
    
    fileprivate func formatTimeForDisplay(time: [Int]) -> String {
        if time.count == 3 {
            return "\(time[0]):\(time[1]).\(time[2])"
        } else {
            return ""
        }
    }
    
    fileprivate func setupPickerViews() {
        let footLabel = UILabel()
        footLabel.text = "ft"
        let inchesLabel = UILabel()
        inchesLabel.text = "             in"
        let heightLabels: [Int: UILabel] = [ 0: footLabel, 1: inchesLabel]
        
        heightPicker.delegate = self
        sidePicker.delegate = self
        heightPicker.dataSource = self
        sidePicker.dataSource = self
        heightPicker.tag = 1
        sidePicker.tag = 2
        heightField.inputView = heightPicker
        sideField.inputView = sidePicker
        heightField.inputAccessoryView = addToolbarItems(buttonTitle: "Done", labelTitle: "")
        sideField.inputAccessoryView = addToolbarItems(buttonTitle: "Done", labelTitle: "")
        heightPicker.setPickerLabels(labels: heightLabels, containedView: heightPicker)
        
        //Time Pickers
        setTimePicker(picker: twoKPicker, tag: 4)
        setTimePicker(picker: fiveKPicker, tag: 5)
        setTimePicker(picker: sixKPicker, tag: 6)
        twoKTimeField.inputView = twoKPicker
        fiveKTimeField.inputView = fiveKPicker
        sixKTimeField.inputView = sixKPicker
        twoKTimeField.inputAccessoryView = addToolbarItems(buttonTitle: "Done", labelTitle: "Select Time")
        fiveKTimeField.inputAccessoryView = addToolbarItems(buttonTitle: "Done", labelTitle: "Select Time")
        sixKTimeField.inputAccessoryView = addToolbarItems(buttonTitle: "Done", labelTitle: "Select Time")
        
        
    }
    
    fileprivate func setTimePickerLabels() {
        //Labels
        let minuteLabel = UILabel(); minuteLabel.text = "Min"
        let secondsLabel = UILabel(); secondsLabel.text = "       Sec"
        let thousandthsLabel = UILabel(); thousandthsLabel.text = "             Th"
        let fourKLabels: [Int: UILabel] = [0: minuteLabel, 1: secondsLabel, 2: thousandthsLabel]
        let fiveKLables: [Int: UILabel] = [0: minuteLabel, 1: secondsLabel, 2: thousandthsLabel]
        let sixKLabels: [Int: UILabel] = [0: minuteLabel, 1: secondsLabel, 2: thousandthsLabel]
        twoKPicker.setPickerLabels(labels: fourKLabels, containedView: twoKPicker)
        fiveKPicker.setPickerLabels(labels: fiveKLables, containedView: fiveKPicker)
        sixKPicker.setPickerLabels(labels: sixKLabels, containedView: sixKPicker)
    }
    
}
