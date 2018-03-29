//
//  PredictionController.swift
//  EyeProfileData
//
//  Created by Jakub Tlach on 1/25/18.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit
import AVFoundation

class PredictionController: UIViewController {

	@IBOutlet weak var eyeView: EyeView!
	@IBOutlet weak var startSwitch: UISwitch!
	@IBOutlet weak var counterLabel: UILabel!
	
	
	// Buttons
	@IBOutlet weak var colorButton1: UIButton!
	@IBOutlet weak var colorButton2: UIButton!
	@IBOutlet weak var colorButton3: UIButton!
	
	@IBOutlet weak var lineButton1: UIButton!
	@IBOutlet weak var lineButton2: UIButton!
	@IBOutlet weak var lineButton3: UIButton!
	
	@IBOutlet weak var positionButton1: UIButton!
	@IBOutlet weak var positionButton2: UIButton!
	@IBOutlet weak var positionButton3: UIButton!
	@IBOutlet weak var positionButton4: UIButton!
	@IBOutlet weak var positionButton5: UIButton!
	
	@IBOutlet weak var typeButton1: UIButton!
	@IBOutlet weak var typeButton2: UIButton!
	@IBOutlet weak var typeButton3: UIButton!
	@IBOutlet weak var typeButton4: UIButton!
	@IBOutlet weak var typeButton5: UIButton!
	@IBOutlet weak var typeButton6: UIButton!
	@IBOutlet weak var typeButton7: UIButton!
	@IBOutlet weak var typeButton8: UIButton!
	
	
	
	// Counters
	@IBOutlet weak var colorCounter1: UILabel!
	@IBOutlet weak var colorCounter2: UILabel!
	@IBOutlet weak var colorCounter3: UILabel!
	
	@IBOutlet weak var lineCounter1: UILabel!
	@IBOutlet weak var lineCounter2: UILabel!
	@IBOutlet weak var lineCounter3: UILabel!
	
	@IBOutlet weak var positionCounter1: UILabel!
	@IBOutlet weak var positionCounter2: UILabel!
	@IBOutlet weak var positionCounter3: UILabel!
	@IBOutlet weak var positionCounter4: UILabel!
	@IBOutlet weak var positionCounter5: UILabel!
	
	@IBOutlet weak var typeCounter1: UILabel!
	@IBOutlet weak var typeCounter2: UILabel!
	@IBOutlet weak var typeCounter3: UILabel!
	@IBOutlet weak var typeCounter4: UILabel!
	@IBOutlet weak var typeCounter5: UILabel!
	@IBOutlet weak var typeCounter6: UILabel!
	@IBOutlet weak var typeCounter7: UILabel!
	@IBOutlet weak var typeCounter8: UILabel!
	
	
	
	// Indexes
	var colorSelectedIndex = 0
	var lineSelectedIndex = 0
	var positionSelectedIndex = 0
	var typeSelectedIndex = 0
	
	var colorSelected = false
	var lineSelected = false
	var positionSelected = false
	var typeSelected = false
	
	
	
	// Arrays
	var eyeColors: [UIButton] = []
	var eyeLines: [UIButton] = []
	var eyePositions: [UIButton] = []
	var eyeTypes: [UIButton] = []
	
	
	
	
	// Loads the counters
	var totalCounter = UserDefaults.standard.integer(forKey: "totalCounter")
	
	var colorCounters: [Int] = UserDefaults.standard.array(forKey: "colorCounters")
		as? [Int] ?? [0, 0, 0]
	
	var lineCounters: [Int] = UserDefaults.standard.array(forKey: "lineCounters")
		as? [Int] ?? [0, 0, 0]
	
	var positionCounters: [Int] = UserDefaults.standard.array(forKey: "positionCounters")
		as? [Int] ?? [0, 0, 0, 0, 0]
	
	var typeCounters: [Int] = UserDefaults.standard.array(forKey: "typeCounters")
		as? [Int] ?? [0, 0, 0, 0, 0, 0, 0, 0]
	
	
	
	// Names of groups
	var groupNames = ["目の色", "まぶたの形", "黒目の割合", "目の形"]
	var groupColors = ["黒色", "茶色", "灰色"]
	var groupLines = ["一重", "二重", "奥二重"]
	var groupPositions = ["普通", "大きめ", "上三白眼", "下三白眼", "四白眼"]
	var groupTypes =
		["丸型", "丸 + アーモンド型", "アーモンド型", "細アーモンド型", "タレ目型", "タレ目半開き型", "半開き型", "アジア人型"]
	
	
	
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: Init
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Turn off the switch
		startSwitch.isOn = false
		
		
		// Init arrays of buttons
		eyeColors.append(colorButton1)
		eyeColors.append(colorButton2)
		eyeColors.append(colorButton3)
		
		eyeLines.append(lineButton1)
		eyeLines.append(lineButton2)
		eyeLines.append(lineButton3)
		
		eyePositions.append(positionButton1)
		eyePositions.append(positionButton2)
		eyePositions.append(positionButton3)
		eyePositions.append(positionButton4)
		eyePositions.append(positionButton5)
		
		eyeTypes.append(typeButton1)
		eyeTypes.append(typeButton2)
		eyeTypes.append(typeButton3)
		eyeTypes.append(typeButton4)
		eyeTypes.append(typeButton5)
		eyeTypes.append(typeButton6)
		eyeTypes.append(typeButton7)
		eyeTypes.append(typeButton8)
		
		
		//  Update of the Counters
		update()
	}
	
	
	
	
	// Update counters
	func update() {
		colorCounter1.text = "x \(colorCounters[0])"
		colorCounter2.text = "x \(colorCounters[1])"
		colorCounter3.text = "x \(colorCounters[2])"
		
		lineCounter1.text = "x \(lineCounters[0])"
		lineCounter2.text = "x \(lineCounters[1])"
		lineCounter3.text = "x \(lineCounters[2])"
		
		positionCounter1.text = "x \(positionCounters[0])"
		positionCounter2.text = "x \(positionCounters[1])"
		positionCounter3.text = "x \(positionCounters[2])"
		positionCounter4.text = "x \(positionCounters[3])"
		positionCounter5.text = "x \(positionCounters[4])"
		
		typeCounter1.text = "x \(typeCounters[0])"
		typeCounter2.text = "x \(typeCounters[1])"
		typeCounter3.text = "x \(typeCounters[2])"
		typeCounter4.text = "x \(typeCounters[3])"
		typeCounter5.text = "x \(typeCounters[4])"
		typeCounter6.text = "x \(typeCounters[5])"
		typeCounter7.text = "x \(typeCounters[6])"
		typeCounter8.text = "x \(typeCounters[7])"
		
		counterLabel.text = "x  \(totalCounter)"
	}
	
	
	
	
	
	
	// Save counters
	func save() {
		UserDefaults.standard.set(colorCounters, forKey: "colorCounters")
		UserDefaults.standard.set(lineCounters, forKey: "lineCounters")
		UserDefaults.standard.set(positionCounters, forKey: "positionCounters")
		UserDefaults.standard.set(typeCounters, forKey: "typeCounters")
		UserDefaults.standard.set(totalCounter, forKey: "totalCounter")
		UserDefaults.standard.synchronize()
	}
	
	
	
	
	
	
	
	
	// When the Switch is ON -> take the pictures of the eye
	func takePhotos() {
		
		// Stop?
		if !startSwitch.isOn {
			return
		}
		
		
		// No Image?
		if eyeView.cameraLayer.contents == nil {
			
			// Continue
			RUTools.runAfter (0.2) { self.takePhotos() }
			return
		}
		
		
		
		// Get image
		let image = eyeView.ruRenderedImage.ruAspectFillToSize(CGSize(width: 100, height: 100))
		
		
		
		
		// Folder for Colors
		let folderColors = RUTools.documentsURL.appendingPathComponent("\(groupNames[0])")
		let pathColors = folderColors.appendingPathComponent("\(self.groupColors[self.colorSelectedIndex])")
		if !FileManager.default.fileExists(atPath: pathColors.path) {
			try? FileManager.default.createDirectory(at: pathColors, withIntermediateDirectories: true, attributes: nil)
		}

		// Folder for Lines
		let folderLines = RUTools.documentsURL.appendingPathComponent("\(groupNames[1])")
		let pathLines = folderLines.appendingPathComponent("\(self.groupLines[self.lineSelectedIndex])")
		if !FileManager.default.fileExists(atPath: pathLines.path) {
			try? FileManager.default.createDirectory(at: pathLines, withIntermediateDirectories: true, attributes: nil)
		}

		// Folder for Positions
		let folderPositions = RUTools.documentsURL.appendingPathComponent("\(groupNames[2])")
		let pathPositions = folderPositions.appendingPathComponent("\(self.groupPositions[self.positionSelectedIndex])")
		if !FileManager.default.fileExists(atPath: pathPositions.path) {
			try? FileManager.default.createDirectory(at: pathPositions, withIntermediateDirectories: true, attributes: nil)
		}

		// Folder for Types
		let folderTypes = RUTools.documentsURL.appendingPathComponent("\(groupNames[3])")
		let pathTypes = folderTypes.appendingPathComponent("\(self.groupTypes[self.typeSelectedIndex])")
		if !FileManager.default.fileExists(atPath: pathTypes.path) {
			try? FileManager.default.createDirectory(at: pathTypes, withIntermediateDirectories: true, attributes: nil)
		}
		
		


		
		// Save the image
		if let data = UIImagePNGRepresentation(image) {
			let path1 = pathColors.appendingPathComponent("\(self.colorCounters[colorSelectedIndex]).png")
			try? data.write(to: path1)
			
			let path2 = pathLines.appendingPathComponent("\(self.lineCounters[lineSelectedIndex]).png")
			try? data.write(to: path2)
			
			let path3 = pathPositions.appendingPathComponent("\(self.positionCounters[positionSelectedIndex]).png")
			try? data.write(to: path3)
			
			let path4 = pathTypes.appendingPathComponent("\(self.typeCounters[typeSelectedIndex]).png")
			try? data.write(to: path4)
		}

		
		
		
		
		// Increase the counter
		totalCounter += 1
		colorCounters[colorSelectedIndex] += 1
		lineCounters[lineSelectedIndex] += 1
		positionCounters[positionSelectedIndex] += 1
		typeCounters[typeSelectedIndex] += 1
		
		update()
		
		
		
		// Continue
		RUTools.runAfter(0.2) { self.takePhotos() }
	}
	
	
	
	
	
	
	
	// Pop up alert message, when user does not have all categories selected
	func showAlertButtonTapped() {
		
		// Create the alert
		let alert = UIAlertController(title: "すべてのカテゴリを選択", message: "❗️❗️❗️", preferredStyle: UIAlertControllerStyle.alert)
		
		// Add an action (button)
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
		
		// Show the alert
		self.present(alert, animated: true, completion: nil)
	}
	
	
	
	
	
	
	
	
	// When the Switch is On, take pictures of the CameraView
	@IBAction func switchStartStop(_ sender: Any) {
		if !colorSelected || !lineSelected || !positionSelected || !typeSelected {
			startSwitch.isOn = false
			showAlertButtonTapped()
			return
		}
		takePhotos()
		save()
	}




	
	
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: Actions
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	// Actions for Color Buttons
	@IBAction func colorButtonSelected1(_ sender: Any) {
		eyeColors[colorSelectedIndex].backgroundColor = UIColor.white
		colorSelectedIndex = 0
		eyeColors[colorSelectedIndex].backgroundColor = UIColor.red
		colorSelected = true
	}
	@IBAction func colorButtonSelected2(_ sender: Any) {
		eyeColors[colorSelectedIndex].backgroundColor = UIColor.white
		colorSelectedIndex = 1
		eyeColors[colorSelectedIndex].backgroundColor = UIColor.red
		colorSelected = true
	}
	@IBAction func colorButtonSelected3(_ sender: Any) {
		eyeColors[colorSelectedIndex].backgroundColor = UIColor.white
		colorSelectedIndex = 2
		eyeColors[colorSelectedIndex].backgroundColor = UIColor.red
		colorSelected = true
	}
	
	
	
	
	// Actions for Line Buttons
	@IBAction func lineButtonSelected1(_ sender: Any) {
		eyeLines[lineSelectedIndex].backgroundColor = UIColor.white
		lineSelectedIndex = 0
		eyeLines[lineSelectedIndex].backgroundColor = UIColor.red
		lineSelected = true
	}
	@IBAction func lineButtonSelected2(_ sender: Any) {
		eyeLines[lineSelectedIndex].backgroundColor = UIColor.white
		lineSelectedIndex = 1
		eyeLines[lineSelectedIndex].backgroundColor = UIColor.red
		lineSelected = true
	}
	@IBAction func lineButtonSelected3(_ sender: Any) {
		eyeLines[lineSelectedIndex].backgroundColor = UIColor.white
		lineSelectedIndex = 2
		eyeLines[lineSelectedIndex].backgroundColor = UIColor.red
		lineSelected = true
	}
	
	
	
	
	// Actions for Position Buttons
	@IBAction func positionButtonSelected1(_ sender: Any) {
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.white
		positionSelectedIndex = 0
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.red
		positionSelected = true
	}
	@IBAction func positionButtonSelected2(_ sender: Any) {
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.white
		positionSelectedIndex = 1
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.red
		positionSelected = true
	}
	@IBAction func positionButtonSelected3(_ sender: Any) {
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.white
		positionSelectedIndex = 2
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.red
		positionSelected = true
	}
	@IBAction func positionButtonSelected4(_ sender: Any) {
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.white
		positionSelectedIndex = 3
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.red
		positionSelected = true
	}
	@IBAction func positionButtonSelected5(_ sender: Any) {
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.white
		positionSelectedIndex = 4
		eyePositions[positionSelectedIndex].backgroundColor = UIColor.red
		positionSelected = true
	}
	
	
	
	
	// Actions for Type Buttons
	@IBAction func typeButtonSelected1(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 0
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected2(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 1
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected3(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 2
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected4(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 3
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected5(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 4
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected6(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 5
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected7(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 6
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}
	@IBAction func typeButtonSelected8(_ sender: Any) {
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.white
		typeSelectedIndex = 7
		eyeTypes[typeSelectedIndex].backgroundColor = UIColor.red
		typeSelected = true
	}

}







