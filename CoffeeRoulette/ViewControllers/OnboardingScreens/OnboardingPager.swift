//
//  OnboardingPager.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-08-01.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit

class OnboardingPager : UIPageViewController {
    
    func getFirstPage() -> FirstOnboardingScreen {
        return storyboard!.instantiateViewController(withIdentifier: "FirstOnboardingScreen") as! FirstOnboardingScreen
    }
    
    override func viewDidLoad() {
        
        
        setViewControllers([getFirstPage()], direction: .forward, animated: false, completion: nil)
        dataSource = self
    }
    
    
    func getSecondPage() -> SecondOnboardingScreen {
        return storyboard!.instantiateViewController(withIdentifier: "SecondOnbordingScreen") as! SecondOnboardingScreen
    }
    
    func getThirdPage() -> ThirdOnboardingScreen {
        return storyboard!.instantiateViewController(withIdentifier: "ThirdOnboardingScreen") as! ThirdOnboardingScreen
    }
    
}

extension OnboardingPager : UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController.isKind(of: FirstOnboardingScreen.self) {
            // 3 - > 2
            return getSecondPage()
        } else if viewController.isKind(of: SecondOnboardingScreen.self) {
            //2 -> 1
            return getFirstPage()
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController.isKind(of: FirstOnboardingScreen.self) {
            // 1 -> 2
            return getSecondPage()
        } else if viewController.isKind(of: SecondOnboardingScreen.self) {
            // 2 -> 3
            return getThirdPage()
        } else {
            //2-> end
            return nil
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 3
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    
    

}
