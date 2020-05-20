//
//  ViewController.swift
//  WhatFlower
//
//  Created by Philip Yu on 7/12/19.
//  Copyright © 2019 Philip Yu. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    // MARK: - Properties
    private let imagePicker = UIImagePickerController()
    private let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set class as delegate
        imagePicker.delegate = self
        
    }
    
    // MARK: - IBAction Section
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        imagePicker.allowsEditing = false
        
        // Present camera, if available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("Camera is available 📸")
            imagePicker.sourceType = .camera
            
            // Present photo library
        } else {
            print("Camera 🚫 available so we will use photo library instead")
            imagePicker.sourceType = .photoLibrary
            // Present imagePicker source type (either camera or library)
        }
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    // MARK: - Private Function Section
    
    private func detect(image: CIImage) {
        
        // Create FlowerClassifier model
        guard let model =  try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model")
        }
        
        // Handles User request to use in model
        let request = VNCoreMLRequest(model: model) { (request, _) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
        
            let name = classification.identifier.capitalized
            let percentage = String.localizedStringWithFormat("%.2f", (classification.confidence * 100))
            
            print("\(percentage)% confidence that picture is: \(name)")
            self.navigationItem.title = "\(name)"
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    private func requestInfo(flowerName: String) {
        
        let parameters: [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1",
            "pithumbsize": "500"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikipedia info.")
                
                let flowerJSON: JSON = JSON(response.result.value!)
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.textView.text = flowerDescription
                self.textView.setContentOffset(.zero, animated: true)
            } else {
                print("Failed to get wikipedia info!")
                print(response)
            }
        }
        
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    
    // MARK: - UIImagePickerControllerDelegate Section
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert to CIImage.")
            }
            
            detect(image: ciImage)
            
            imageView.image = userPickedImage
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
}
