//
//  ImageData.swift
//  CyberGrid
//
//  Created by Robert Haynes on 23/01/2025.
//
import UIKit

extension UIImage {
    var data: Data? {
        if let data = self.pngData() {
            return data
        } else {
            return nil
        }
    }
}

extension Data {
    var image: UIImage? {
        if let image = UIImage(data: self) {
            return image
        } else {
            return nil
        }
    }
}
