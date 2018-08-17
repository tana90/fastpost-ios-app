//
//  Analizer.swift
//  FastPost
//
//  Created by Tudor Ana on 5/24/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreML

final class Analizer {
    
    static let shared: Analizer = {
        let instance = Analizer()
        return instance
    }()
    
    let picObject = PicObject()
    
    
    func analize(image: UIImage, completion result: @escaping (Bool) -> ()) {
        
        var data: [String] = []
        
        DispatchQueue.main.async { [weak self] in
            guard let _ = self else { return }
            
            self!.analizeObjects(from: image) { [weak self] (firstResult) in
                guard let _ = self else { return }
                data.append("#\(firstResult)")
                
                        
                        if data.count > 0 {
                            
                            if let keyword = data.first?.replacingOccurrences(of: "#", with: "") {
                                Connector.shared.getHashtagsFor(keyword: keyword, completion: { [weak self] (json) in
                                    guard let _ = self,
                                        let _ = json.array else {
                                            result(true)
                                            return
                                    }
                                    
                                    if (json.array?.count)! > 0 {
                                        
                                        
                                        json.array?.forEach { (element) in
                                            
                                            if let _ = element.string {
                                                
                                                if (element.string?.lowercased().hasPrefix("hash"))! {
                                                    data.append("#fastpostapp")
                                                } else {
                                                    data.append(String(format: "#%@", element.string!.lowercased()))
                                                }
                                            }
                                        }
                                        
                                        DispatchQueue.main.safeAsync {
                                            data = data.removeDuplicates()
                                            data.enumerated().forEach { (count, result) in
                                                var hashtag = TagData()
                                                hashtag.selected = allowAutoSelect == true ? (count < 20) : false
                                                hashtag.favorite = false
                                                hashtag.tag = result
                                                Tag.add(tagData: hashtag)
                                                
                                            }
                                            CoreDataManager.shared.saveContext()
                                            result(true)
                                        }
                                    } else {
                                        result(true)
                                    }
                                })
                            }
                        } else {
                            result(false)
                        }
            }
        }
    }
    
    
    
    
    
    
    static func prepareResults(result: String) -> String {
        po(result)
        var value = result
        value = value.components(separatedBy: " ")[1]
        value = value.replacingOccurrences(of: ", ", with: ",")
        value = value.replacingOccurrences(of: " ", with: "")
        value = value.replacingOccurrences(of: "_", with: "")
        value = value.replacingOccurrences(of: "-", with: "")
        value = value.replacingOccurrences(of: "/", with: ",")
        value = value.replacingOccurrences(of: ",", with: "")
        value = value.components(separatedBy: CharacterSet.decimalDigits).joined()
        
        return value
    }
    
    func analizeObjects(from image: UIImage, _ results: @escaping (String) -> ()) {
        
        do {
            let prediction = try picObject.prediction(data: resize(size: 224, pixelBuffer: buffer(from: image)!)!)
            DispatchQueue.main.async {
                if let _ = prediction.prob[prediction.classLabel] {
                    results(Analizer.prepareResults(result: prediction.classLabel))
                }
            }
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }
}
