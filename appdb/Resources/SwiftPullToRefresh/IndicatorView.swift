//
//  IndicatorView.swift
//  SwiftPullToRefresh
//
//  Created by ned on 15/03/2018.
//  Copyright © 2018 ned. All rights reserved.
//
//  Source: https://github.com/WXGBridgeQ/SwiftPullToRefresh

import UIKit

class IndicatorView: RefreshView {

    lazy var arrowLayer: CAShapeLayer = {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: 0, y: -8))
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: 5.66, y: 2.34))
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: -5.66, y: 2.34))

        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.theme_strokeColor = Color.arrowLayerStrokeCGColor
        layer.lineWidth = 2
        layer.lineCap = .round
        return layer
    }()
    
    let indicator = UIActivityIndicatorView(style: .gray)
    
    private let isHeader: Bool
    
    init(isHeader: Bool, height: CGFloat, positiveOffset: CGFloat = 0, action: @escaping () -> Void) {
        self.isHeader = isHeader
        super.init(style: isHeader ? .header : .footer, height: height, positiveOffset: positiveOffset, action: action)
        
        indicator.theme_activityIndicatorViewStyle = [.gray, .white, .white]
        
        layer.addSublayer(arrowLayer)
        addSubview(indicator)
        alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        arrowLayer.position = center
        indicator.center = center
    }
    
    override func didUpdateState(_ isRefreshing: Bool) {
        arrowLayer.isHidden = isRefreshing
        isRefreshing ? indicator.startAnimating() : indicator.stopAnimating()
    }
    
    override func didUpdateProgress(_ progress: CGFloat) {
        alpha = progress
        let rotation = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
        if isHeader {
            arrowLayer.transform = progress == 1 ? rotation : CATransform3DIdentity
        } else {
            arrowLayer.transform = progress == 1 ? CATransform3DIdentity : rotation
        }
    }
    
}

