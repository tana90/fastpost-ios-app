//
//  KeyboardConfigViewController.swift
//  FastPost
//
//  Created by Tudor Ana on 6/10/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class KeyboardConfigViewController: UITableViewController {
    
    @IBAction func closeAction() {
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension KeyboardConfigViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        closeAction()
    }
}
