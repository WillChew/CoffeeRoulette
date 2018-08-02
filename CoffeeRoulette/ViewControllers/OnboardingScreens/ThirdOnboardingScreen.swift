//
//  ThirdOnboardingScreen.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-08-01.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit

class ThirdOnboardingScreen: UIViewController {

    @IBOutlet weak var getStartedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .brown
        getStartedButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        getStartedButton.setTitleColor(UIColor(red:0.27, green:0.22, blue:0.14, alpha:1.0), for: .normal)
        getStartedButton.layer.cornerRadius = getStartedButton.frame.height / 2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func getStartedButtonPressed(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "hasLaunched")
    }
    
    //    func goToMainApp() -> CoffeeRouletteViewController {
//        return storyboard!.instantiateViewController(withIdentifier: "CoffeeRouletteViewController") as! CoffeeRouletteViewController
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
