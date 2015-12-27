//
//  ViewController.swift
//  SoftJSON
//
//  Created by Goppinath Thurairajah on 25.12.15.
//  Copyright © 2015 Goppinath Thurairajah. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let file = NSBundle(forClass: ViewController.self).pathForResource("sample", ofType: "json"), let data = NSData(contentsOfFile: file) {
            
            var JSON = SoftJSON(data: data)
            
            print(JSON["widget"]?["justABool"])
            
            JSON["widget"] = SoftJSON(dictionary: ["justABool": false])
            
            print(JSON["widget"]?["justABool"])
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

