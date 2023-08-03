//
//  DeviceStatusCell.swift
//  appdb
//
//  Created by ned on 22/05/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

class DeviceStatusCell: UITableViewCell {

    var statusLeft, typeLeft, titleLeft, bundleLeft, purposeLeft, acknowledgedLeft, statusShortLeft, statusTextLeft: UILabel!
    var status, type, title, bundle, purpose, acknowledged, statusShort, statusText: UILabel!

    var timestamp: UILabel!

    var moreImageButton: UIImageView!

    func updateContent(with item: DeviceStatusItem) {
        timestamp.text = prettify(item.timestamp)
        status.text = prettify(item.status)
        type.text = prettify(item.type)
        title.text = prettify(item.title)
        bundle.text = prettify(item.bundleId)
        purpose.text = prettify(item.purpose)
        acknowledged.text = prettify(item.acknowledged)
        statusShort.text = prettify(item.statusShort)
        statusText.text = prettify(item.statusText)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // UI
        setBackgroundColor(Color.veryVeryLightGray)
        theme_backgroundColor = Color.veryVeryLightGray

        // Add separator
        let line = UIView()
        line.theme_backgroundColor = Color.borderColor
        addSubview(line)
        constrain(line) { line in
            line.height ~== 1 / UIScreen.main.scale
            line.leading ~== line.superview!.leading
            line.trailing ~== line.superview!.trailing
            line.top ~== line.superview!.bottom ~- (1 / UIScreen.main.scale)
        }

        selectionStyle = .none

        status = generateLabel(); statusLeft = generateLabel(text: "Status")
        type = generateLabel(); typeLeft = generateLabel(text: "Type")
        title = generateLabel(); titleLeft = generateLabel(text: "Title")
        bundle = generateLabel(); bundleLeft = generateLabel(text: "Bundle id")
        purpose = generateLabel(); purposeLeft = generateLabel(text: "Purpose")
        acknowledged = generateLabel(); acknowledgedLeft = generateLabel(text: "Acknowledged")
        statusShort = generateLabel(); statusShortLeft = generateLabel(text: "Status Short")
        statusText = generateLabel(); statusTextLeft = generateLabel(text: "Status Text")

        timestamp = UILabel()
        timestamp.theme_textColor = Color.timestampGray
        timestamp.font = .systemFont(ofSize: (11 ~~ 10))
        timestamp.makeDynamicFont()
        timestamp.numberOfLines = 1
        timestamp.textAlignment = Global.isRtl ? .left : .right

        moreImageButton = UIImageView(image: #imageLiteral(resourceName: "more"))
        moreImageButton.alpha = 0.8
        moreImageButton.isHidden = true

        contentView.addSubview(status); contentView.addSubview(statusLeft)
        contentView.addSubview(type); contentView.addSubview(typeLeft)
        contentView.addSubview(title); contentView.addSubview(titleLeft)
        contentView.addSubview(bundle); contentView.addSubview(bundleLeft)
        contentView.addSubview(purpose); contentView.addSubview(purposeLeft)
        contentView.addSubview(acknowledged); contentView.addSubview(acknowledgedLeft)
        contentView.addSubview(statusShort); contentView.addSubview(statusShortLeft)
        contentView.addSubview(statusText); contentView.addSubview(statusTextLeft)
        contentView.addSubview(timestamp); contentView.addSubview(moreImageButton)

        setConstraints()
    }

    private func setConstraints() {
        let space: CGFloat = (25 ~~ 15)
        let margin: CGFloat = (6 ~~ 4)

        constrain(moreImageButton) { more in
            more.centerY ~== more.superview!.centerY
            more.trailing ~== more.superview!.trailing ~- Global.Size.margin.value
            more.width ~== (22 ~~ 20)
            more.height ~== more.width
        }

        constrain(statusLeft, status, timestamp) { statusLeft, status, timestamp in
            timestamp.top ~== timestamp.superview!.top ~+ (12 ~~ 10)
            timestamp.trailing ~== timestamp.superview!.trailing ~- Global.Size.margin.value
            timestamp.height ~>= 16

            statusLeft.top ~== statusLeft.superview!.top ~+ (15 ~~ 12)
            statusLeft.leading ~== statusLeft.superview!.leading ~+ Global.Size.margin.value
            statusLeft.trailing ~== statusLeft.leading ~+ (130 ~~ 95)

            status.leading ~== statusLeft.trailing ~+ space
            status.trailing ~== status.superview!.trailing ~- Global.Size.margin.value ~- (60 ~~ 55)
            status.top ~== statusLeft.top

            constrain(typeLeft, type) { typeLeft, type in
                (typeLeft.top ~== status.bottom ~+ margin) ~ Global.notMaxPriority
                typeLeft.leading ~== statusLeft.leading
                typeLeft.trailing ~== statusLeft.trailing

                type.leading ~== typeLeft.trailing ~+ space
                type.trailing ~== type.superview!.trailing ~- Global.Size.margin.value
                type.top ~== typeLeft.top

                constrain(titleLeft, title) { titleLeft, title in
                    (titleLeft.top ~== type.bottom ~+ margin) ~ Global.notMaxPriority
                    titleLeft.leading ~== typeLeft.leading
                    titleLeft.trailing ~== typeLeft.trailing

                    title.leading ~== titleLeft.trailing ~+ space
                    title.trailing ~== title.superview!.trailing ~- Global.Size.margin.value
                    title.top ~== titleLeft.top

                    constrain(bundleLeft, bundle) { bundleLeft, bundle in
                        (bundleLeft.top ~== title.bottom ~+ margin) ~ Global.notMaxPriority
                        bundleLeft.leading ~== titleLeft.leading
                        bundleLeft.trailing ~== titleLeft.trailing

                        bundle.leading ~== bundleLeft.trailing ~+ space
                        bundle.trailing ~== bundle.superview!.trailing ~- Global.Size.margin.value
                        bundle.top ~== bundleLeft.top

                        constrain(purposeLeft, purpose) { purposeLeft, purpose in
                            (purposeLeft.top ~== bundle.bottom ~+ margin) ~ Global.notMaxPriority
                            purposeLeft.leading ~== bundleLeft.leading
                            purposeLeft.trailing ~== bundleLeft.trailing

                            purpose.leading ~== purposeLeft.trailing ~+ space
                            purpose.trailing ~== purpose.superview!.trailing ~- Global.Size.margin.value ~- (22 ~~ 20)
                            purpose.top ~== purposeLeft.top

                            constrain(acknowledgedLeft, acknowledged) { ackLeft, ack in
                                (ackLeft.top ~== purpose.bottom ~+ margin) ~ Global.notMaxPriority
                                ackLeft.leading ~== purposeLeft.leading
                                ackLeft.trailing ~== purposeLeft.trailing

                                ack.leading ~== ackLeft.trailing ~+ space
                                ack.trailing ~== ack.superview!.trailing ~- Global.Size.margin.value
                                ack.top ~== ackLeft.top

                                constrain(statusShortLeft, statusShort) { statusShortLeft, statusShort in
                                    (statusShortLeft.top ~== ack.bottom ~+ margin) ~ Global.notMaxPriority
                                    statusShortLeft.leading ~== ackLeft.leading
                                    statusShortLeft.trailing ~== ackLeft.trailing

                                    statusShort.leading ~== statusShortLeft.trailing ~+ space
                                    statusShort.trailing ~== statusShort.superview!.trailing ~- Global.Size.margin.value
                                    statusShort.top ~== statusShortLeft.top

                                    constrain(statusTextLeft, statusText) { statusTextLeft, statusText in
                                        (statusTextLeft.top ~== statusShort.bottom ~+ margin) ~ Global.notMaxPriority
                                        statusTextLeft.leading ~== statusShortLeft.leading
                                        statusTextLeft.trailing ~== statusShortLeft.trailing

                                        statusText.leading ~== statusTextLeft.trailing ~+ space
                                        statusText.trailing ~== statusText.superview!.trailing ~- Global.Size.margin.value
                                        statusText.top ~== statusTextLeft.top
                                        statusText.bottom ~== statusText.superview!.bottom ~- 15
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension DeviceStatusCell {
    private func generateLabel(text: String = "") -> UILabel {
        let isContent: Bool = text.isEmpty
        let label = UILabel()
        label.text = text
        label.theme_textColor = isContent ? Color.darkGray : Color.title
        label.font = .systemFont(ofSize: (13.5 ~~ 12.5))
        label.makeDynamicFont()
        label.numberOfLines = isContent ? 0 : 1
        label.textAlignment = isContent ? (Global.isRtl ? .right : .left) : (Global.isRtl ? .left : .right)
        return label
    }

    private func prettify(_ text: String) -> String {
        text.isEmpty ? "N/A" : text
    }
}
