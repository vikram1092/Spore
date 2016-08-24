//
//  SnapTimer.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/25/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import UIKit
import AVFoundation


class SnapTimer: UIView {
    
    var timer = CAShapeLayer()
    var timerView = UIView()
    var timerBackground = UIView()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        super.init(coder: aDecoder)
        
        let frame = super.frame
        self.transform = CGAffineTransformMakeRotation( -90.0 * CGFloat(M_PI) / 180.0)
        
        //Set background
        timerBackground = UIView(frame: self.bounds)
        let blurView = UIVisualEffectView(frame: self.bounds)
        blurView.effect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        timerBackground.addSubview(blurView)
        timerBackground.layer.cornerRadius = self.bounds.width/2
        timerBackground.clipsToBounds = true
        
        /*
        timerBackground.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        timerBackground.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor
        */
        
        //Set timer
        timer.path = UIBezierPath(ovalInRect: CGRect(x: 3.0, y: 3.0, width: frame.width - 6.0, height: frame.height - 6.0)).CGPath
        timer.fillColor = UIColor.clearColor().CGColor
        timer.strokeColor = UIColor.whiteColor().CGColor
        timer.lineWidth = 2
        timer.strokeStart = 0.0
        timer.strokeEnd = 1.0
        timer.lineCap = kCALineCapRound
        
        //Set timer view
        timerView = UIView(frame: self.bounds)
        
        //Add sub layers to the view's layer
        self.addSubview(timerBackground)
        timerView.layer.addSublayer(timer)
        self.addSubview(timerView)
    }
    
    
    internal func startTimer(duration: CMTime) {
        
        //Turn on
        print("Turning timer on")
        self.alpha = 1
        
        //Animate the timer
        print("Timer duration: \(duration.seconds)")
        let animation = CABasicAnimation(keyPath: "strokeStart")
        
        //Adding a .3 second due to processing lag for the video
        animation.duration = duration.seconds + 0.3
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        timer.addAnimation(animation, forKey: nil)
        
    }
    
}