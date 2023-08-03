//
//  PortraitScreenshotSearchCell+Stars.swift
//  appdb
//
//  Created by ned on 07/10/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

import AlamofireImage
import Cosmos

class PortraitScreenshotSearchCellWithStars: PortraitScreenshotSearchCell {

    var stars: CosmosView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        name.numberOfLines = 1

        stars = buildStars()

        contentView.addSubview(stars)

        constrain(seller, stars) { seller, stars in
            stars.leading ~== seller.leading
            stars.trailing ~<= stars.superview!.trailing ~- Global.Size.margin.value
            stars.top ~== seller.bottom ~+ (7 ~~ 6)
        }
    }

    override func configure(with item: Item) {
        super.configure(with: item)
        stars.rating = item.itemNumberOfStars
        stars.text = item.itemRating
    }

    private func buildStars() -> CosmosView {
        let stars = CosmosView()
        stars.settings.starSize = 12
        stars.settings.updateOnTouch = false
        stars.settings.textFont = .systemFont(ofSize: 12 ~~ 11)
        stars.settings.totalStars = 5
        stars.settings.fillMode = .half
        stars.settings.textMargin = 2
        stars.settings.starMargin = 0
        return stars
    }
}
