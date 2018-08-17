//
//  RepostPreviewViewController.swift
//  FastPost
//
//  Created by Tudor Ana on 6/27/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import Photos
import StoreKit

final class RepostPreviewViewController: UITableViewController {
    
    var instagramURL: URL = URL(string: "instagram://")!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    
    var selectedRepost: Repost?
    
    @IBAction func closeAction() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func postAction() {
        
        
        if MaxReposts + RateAppOffer > Int(AppManager.loadNumberOfReposts()) ?? 0 || PROVersion {
            
            
            
            let alertViewController = UIAlertController(title: "Caption copied to clipboard", message: "Paste them in Instagram in Caption area. 👏", preferredStyle: .alert)
            
            alertViewController.view.tintColor = UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1)
            let openAction = UIAlertAction(title: "Open Instagram", style: .default) { [unowned self] (alert) in
                guard let image = self.imageView.image else { return }
                self.savePhoto(image: image, completion: {
                    
                    DispatchQueue.main.safeAsync { [weak self] in
                        guard let _ = self else { return }
                        AppManager.incrementNumberOfReposts()
                        EventManager.shared.sendEvent(name: "repost_repost", type: "action")
                        self!.prepareInstagramUrl()
                        UIPasteboard.general.string = self!.captionLabel.text
                        self?.openInsagram()
                    }
                })
            }
            
            let saveAction = UIAlertAction(title: "Save photo", style: .default) { [unowned self] (alert) in
                guard let image = self.imageView.image else { return }
                self.savePhoto(image: image, completion: {
                    
                    DispatchQueue.main.safeAsync { [weak self] in
                        guard let _ = self else { return }
                        AppManager.incrementNumberOfReposts()
                        EventManager.shared.sendEvent(name: "repost_save_photo", type: "action")
                        let alertViewController = UIAlertController(title: "🎉", message: "Photo saved to Camera Roll", preferredStyle: .alert)
                        alertViewController.view.tintColor = UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1)
                        let okAction = UIAlertAction(title: "Close", style: .cancel) { (alert) in
                        }
                        
                        alertViewController.addAction(okAction)
                        self!.present(alertViewController, animated: true, completion: nil)
                    }
                    
                    
                })
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            }
            
            alertViewController.addAction(openAction)
            alertViewController.addAction(saveAction)
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
        } else {
            var style: UIAlertControllerStyle = .actionSheet
            if UI_USER_INTERFACE_IDIOM() == .pad {
                style = .alert
            }
            let alertViewController = UIAlertController(title: "Reposts limit reached", message: "You have reach the limit of \(MaxReposts + RateAppOffer) free reposts. To continue repost upgrade to PRO.", preferredStyle: style)
            alertViewController.view.tintColor = UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1)
            let upgradeAction = UIAlertAction(title: "Upgrade to PRO", style: .default) { [weak self] (alert) in
                guard let _ = self else { return }
                self!.performSegue(withIdentifier: "showStoreSegue", sender: self!)
            }
            
            let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (alert) in
                
                self.showRateTip()
            }
            
            alertViewController.addAction(upgradeAction)
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = selectedRepost else { return }
        
        EventManager.shared.sendEvent(name: "open_repost_preview", type: "app")
        
        usernameLabel.text = selectedRepost!.username
        captionLabel.text = selectedRepost!.caption
        captionLabel.colorHashtag(with: UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1))
        requestSavePhotoPermission()
        
        guard let imageUrl = URL(string: selectedRepost!.imageUrl!) else { return }
        imageView.kf.setImage(with: imageUrl)
        
        guard let profileUrl = URL(string: selectedRepost!.profileUrl!) else { return }
        profileImageView.kf.setImage(with: profileUrl)
        
        
    }
}

extension RepostPreviewViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}


extension RepostPreviewViewController {
    
    func requestSavePhotoPermission() {
        PHPhotoLibrary.shared().performChanges({
        }, completionHandler: { success, error in
        })
    }
    
    
    func prepareInstagramUrl() {
        let lastPHAsset = self.fetchLatestPhotos(forCount: 1)
        guard let asset = lastPHAsset.firstObject else { return }
        
        var id = asset.localIdentifier
        if id.contains("/") {
            if let first = id.components(separatedBy: "/").first {
                id = first
            }
        }
        let assetLibrary = String(format: "assets-library://asset/asset.JPG?id=%@&ext=JPG", id)
        let instaUrl = String(format: "instagram://library?AssetPath=%@", assetLibrary.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
        if let url = URL(string: instaUrl) {
            self.instagramURL = url
        }
    }
    
    
    func savePhoto(image: UIImage, completion: @escaping () -> () ) {
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if success {
                
                completion()
                
            }
            else if let _ = error {
            }
            else {
                
            }
        })
    }
    
    
    
    func fetchLatestPhotos(forCount count: Int?) -> PHFetchResult<PHAsset> {
        
        // Create fetch options.
        let options = PHFetchOptions()
        
        // If count limit is specified.
        if let count = count { options.fetchLimit = count }
        
        // Add sortDescriptor so the lastest photos will be returned.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        options.sortDescriptors = [sortDescriptor]
        
        // Fetch the photos.
        return PHAsset.fetchAssets(with: .image, options: options)
        
    }
    
    
    func openInsagram() {
        
        UIApplication.shared.open(instagramURL, options: [:], completionHandler: { [weak self] (success) in
            
            if !success {
                guard let _ = self else { return }
                let alertViewController = UIAlertController(title: "Instagram app not found", message: "Looks like you don't have Instagram app installed", preferredStyle: .alert)
                alertViewController.view.tintColor = UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1)
                let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                }
                
                alertViewController.addAction(okAction)
                self!.present(alertViewController, animated: true, completion: nil)
            }
        })
    }
    
    
    
    func showRateTip() {
        
        if !PROVersion {
            
            if ShowRateTip == false {
                ShowRateTip = true
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    let alertViewController = UIAlertController(title: "FastPost", message: "Rate our app and get 5 free more reposts.", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1)
                    let okAction = UIAlertAction(title: "Rate app", style: .cancel) { (alert) in
                        SKStoreReviewController.requestReview()
                        
                        if RateAppOffer == 0 {
                            let alertViewController = UIAlertController(title: "🎉", message: "Now you have 5 free more reposts", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 24/255, green: 86/255, blue: 133/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) {(alert) in
                            }
                            alertViewController.addAction(okAction)
                            self!.present(alertViewController, animated: true, completion: nil)
                            
                            EventManager.shared.sendEvent(name: "rate_app", type: "action")
                        }
                        
                        RateAppOffer = 5
                    }
                    let cancelAction = UIAlertAction(title: "Later", style: .default) { (alert) in
                    }
                    
                    alertViewController.addAction(okAction)
                    alertViewController.addAction(cancelAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
