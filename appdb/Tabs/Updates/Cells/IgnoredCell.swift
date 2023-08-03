//
//  IgnoredCell.swift
//  appdb
//
//  Created by ned on 10/11/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

class IgnoredCell: UITableViewCell {

    var name: UILabel!
    var icon: UIImageView!
    var removeButton: UIButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func configure(with text: String, image: String) {
        name.text = text
        if let url = URL(string: image) {
            icon.af.setImage(withURL: url, placeholderImage: #imageLiteral(resourceName: "placeholderIcon"), filter: Global.roundedFilter(from: 30), imageTransition: .crossDissolve(0.2))
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Margins
        contentView.preservesSuperviewLayoutMargins = false
        preservesSuperviewLayoutMargins = false
        layoutMargins.left = 0
        separatorInset.left = 0

        // UI
        setBackgroundColor(Color.veryVeryLightGray)
        theme_backgroundColor = Color.veryVeryLightGray
        selectionStyle = .none

        // Icon
        icon = UIImageView()
        icon.layer.cornerRadius = Global.cornerRadius(from: 30)
        icon.image = #imageLiteral(resourceName: "placeholderIcon")
        icon.layer.borderWidth = 0.5
        icon.layer.theme_borderColor = Color.borderCgColor

        // Name
        name = UILabel()
        name.font = .systemFont(ofSize: (16 ~~ 15))
        name.numberOfLines = 0
        name.theme_textColor = Color.title
        name.makeDynamicFont()

        // Remove button
        removeButton = UIButton(type: .system)
        removeButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        removeButton.setImage(UIImage(named: "remove"), for: .normal)
        removeButton.theme_tintColor = Color.darkGray
        removeButton.contentMode = .scaleAspectFit
        accessoryView = removeButton as UIView

        contentView.addSubview(icon)
        contentView.addSubview(name)

        setConstraints()
    }

    private func setConstraints() {
        constrain(icon, name) { icon, name in
            icon.width ~== 30
            icon.height ~== icon.width

            icon.leading ~== icon.superview!.leading ~+ (25 ~~ 18)
            icon.centerY ~== icon.superview!.centerY

            name.leading ~== icon.trailing ~+ (12 ~~ 10)
            name.trailing ~== name.superview!.trailing ~- 30
            name.centerY ~== icon.centerY
        }
    }
}
