//
//  TabbarViewController.swift
//  FastPost
//
//  Created by Tudor Ana on 7/16/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class TabbarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        EventHandler.shared.repostAvailable {
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                
                if self!.selectedIndex != 2 {
                    let alertViewController = UIAlertController(title: "🌅 New photo found for Repost", message: "Do you want to repost it?", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let repostAction = UIAlertAction(title: "Repost now", style: .default) { [weak self] (alert) in
                        guard let _ = self else { return }
                        self!.selectedIndex = 2
                    }
                    
                    let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (alert) in
                    }
                    
                    alertViewController.addAction(repostAction)
                    alertViewController.addAction(cancelAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
                
            }
        }
    }
}
