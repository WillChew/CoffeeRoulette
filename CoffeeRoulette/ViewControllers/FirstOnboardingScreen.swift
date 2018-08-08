//
//  FirstOnboardingScreen.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-08-01.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import ChameleonFramework


class FirstOnboardingScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
