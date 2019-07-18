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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Outlets
    @IBOutlet weak var imageView: UIImageView!
    
    // Properties
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert to CIImage.")
            }
            
            detect(image: ciImage)
            
            imageView.image = userPickedImage as? UIImage
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        // Create FlowerClassifier model
        guard let model =  try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model")
        }
        
        // Handles User request to use in model
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
        ]

        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikipedia info.")
                print(JSON(response.result))
            } else {
                print("Failed to get wikipedia info!")
                print(response)
            }
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
}

