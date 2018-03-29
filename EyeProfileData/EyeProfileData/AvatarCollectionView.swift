//
//  CollectionView.swift
//  iAvatar
//
//  Created by Jakub Tlach on 1/10/18.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit

class AvatarCollectionView: UICollectionView {
	
	var avatars: [String] = []
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		delegate = self
		dataSource = self
	}
	
	func addAvatar(_ id: String) {
		
		// Already exists?
		if avatars.contains(id) {
			return
		}
		
		// Add
		avatars.append(id)
		self.reloadData()
	}
}






/////////////////////////////////////////////////////////////
// MARK: - DataSource
/////////////////////////////////////////////////////////////

extension AvatarCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return avatars.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = self.dequeueReusableCell(withReuseIdentifier: "AvatarCell", for: indexPath) as! AvatarCell
		cell.avatarID = avatars[indexPath.row]
		return cell
	}
}








/////////////////////////////////////////////////////////////
// MARK: - AvatarCell
/////////////////////////////////////////////////////////////

class AvatarCell: UICollectionViewCell {
	
	
	@IBOutlet weak var button: UIButton!

	private var _avatarID: String = ""
	var avatarID: String {
		get {
			return _avatarID
		}
		set {
			_avatarID = newValue
			if let image = Avatar(id: _avatarID).image {
				button.setImage(image, for: .normal)
			} else {
				
				// TODO: Default Image
				button.setImage(nil, for: .normal)
			}
		}
	}
	
}







