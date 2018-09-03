//
//  EquipmentEditorViewController.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/12/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import SkyFloatingLabelTextField

class EquipmentEditorViewController: UIViewController {

    
    @IBOutlet weak var nameField: SkyFloatingLabelTextField!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var equipmentTypeField: SkyFloatingLabelTextField!
    
    var equipmentIsBoat = false
    var editingEquipment = false
    var currentEquipment: Equipment?
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let equipmentTypes = ["", "Boat", "Oar"]
    let pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureEquipmentPicker()
        setupButtons()
        
        if equipmentIsBoat {
            equipmentTypeField.text = "Boat"
            setNameTextField(to: "Boat", for: nameField)
        } else {
            equipmentTypeField.text = "Oar"
            setNameTextField(to: "Oar", for: nameField)
        }
        
        if editingEquipment {
            if let equipment = currentEquipment {
                nameField.text = equipment.name ?? "Error"
                if let imageData = equipment.image as Data? {
                    let newImage = UIImage(data: imageData as Data)
                    imageView.image = newImage
                } else {
                    imageView.image = UIImage(named: "noEquipmentImage")
                }
            } else { print("No Equipment") }
        }
    }
    
    fileprivate func setNameTextField(to equipment: String, for textField: SkyFloatingLabelTextField) {
        textField.titleLabel.text = equipment
        textField.placeholder = "Enter \(equipment.lowercased()) name"
        textField.selectedTitle = "\(equipment) Name"
    }
    
    fileprivate func setupButtons() {
        style(button: saveButton)
        style(button: takePictureButton)
    }
    
    @IBAction func takePictureAction(_ sender: Any) {
        
    }
    
    @IBAction func saveAction(_ sender: Any) {
        if editingEquipment {
            setCurrentEquipmentData()
        } else {
            setNewEquipmentData()
        }
    }
    
    fileprivate func setCurrentEquipmentData() {
        guard let equipment = currentEquipment else { showError(message: "No Equiment Data."); return }
        guard let name = nameField.text, !name.isEmpty else { showError(message: "Please provide a valid equipment name."); return }
        guard let equipmentType = equipmentTypeField.text, !equipmentType.isEmpty else { showError(message: "Please select an equipment type."); return }
        equipment.name = name
        equipment.type = equipmentType.lowercased()
        
        //Image
        if let equipmentImage = imageView.image {
            if let imageData = equipmentImage.jpegData(compressionQuality: 1) {
                equipment.image = imageData
            }
        }
        saveCoreData()
    }
    
    fileprivate func setNewEquipmentData() {
        guard let name = nameField.text, !name.isEmpty else { showError(message: "Please provide a valid equipment name."); return }
        guard let equipmentType = equipmentTypeField.text, !equipmentType.isEmpty else { showError(message: "Please select an equipment type."); return }
        if let newEquipment = NSEntityDescription.insertNewObject(forEntityName: "Equipment", into: managedContext) as? Equipment {
            newEquipment.id = UUID().uuidString
            newEquipment.name = name
            newEquipment.type = equipmentType.lowercased()
            
            if let equipmentImage = imageView.image {
                if let imageData = equipmentImage.jpegData(compressionQuality: 1) {
                    newEquipment.image = imageData
                }
            }
            print(newEquipment)
            saveCoreData()
        } else {
            showError(message: "There was an error creating the data object.  Please try again.")
        }
    }
    
    fileprivate func saveCoreData() {
        do {
            try managedContext.save()
            print("Equipment Save Successful")
            navigationController?.popViewController(animated: true)
        } catch {
            print("Equipment Save Error: \(error)")
            showError(message: error.localizedDescription)
        }
    }
    
    fileprivate func configureEquipmentPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        equipmentTypeField.inputView = pickerView
        equipmentTypeField.inputAccessoryView = addToolbarItems(buttonTitle: "Select", labelTitle: "Select Equipment Type")
    }
    
    fileprivate func addToolbarItems(buttonTitle: String, labelTitle: String) -> UIToolbar {
        // Create Toolbar Items
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
        toolbar.barStyle = UIBarStyle.default
        toolbar.tintColor = UIColor.black
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed(sender:)))
        doneButton.title = buttonTitle
        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
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

extension EquipmentEditorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return equipmentTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        equipmentTypeField.text = equipmentTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return equipmentTypes[row]
    }
    
    
}
