//
//  SoftJSON.swift
//  SoftJSON
//
//  Created by Goppinath Thurairajah on 25.12.15.
//  Copyright © 2015 Goppinath Thurairajah. http://goppinath.com
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation

struct SoftJSON {
    
    enum JSONContent {
        
        case _Object([String:AnyObject])
        case _Array([AnyObject])
        case _String(String)
        case _Bool(Bool)
        case _Number(NSNumber)
        case _Null
    }
    
    private var content: JSONContent = ._Null
    
    private var anyObject: AnyObject? {
        
        get {
            
            switch content {
            case ._Object(let dictionary):  return dictionary
            case ._Array(let array):        return array
            case ._String(let string):      return string
            case ._Bool(let bool):          return bool
            case ._Number(let number):      return number
            case ._Null:                    return NSNull()
            }
        }
        set {
            
            if let anyObject = newValue {
                
                switch anyObject {
                case let object as [String:AnyObject]:  content = ._Object(object)
                case let array as [AnyObject]:          content = ._Array(array)
                case let string as String:              content = ._String(string)
                case let number as NSNumber:            if number.isBool() { content = ._Bool(number.boolValue) } else { content = ._Number(number) }
                case _ as NSNull:                       content = ._Null
                default: break
                }
            }
        }
    }
    
    private init(anyObject: AnyObject?) {
        
        self.anyObject = anyObject
    }
    
    init(data: NSData, JSONReadingOptions: NSJSONReadingOptions = .AllowFragments) {
        
        var anyObject: AnyObject?
        
        do { anyObject = try NSJSONSerialization.JSONObjectWithData(data, options: []) }
        catch { }
        
        self.init(anyObject: anyObject)
    }
    
    init(dictionary: [String:AnyObject] = [String:AnyObject]()) {
        
        self.init(anyObject: dictionary)
    }
    
    init(value: AnyObject, key: String) {
        
        self.init(dictionary: [key : value])
    }
    
//    func rawData(JSONWritingOptions: NSJSONWritingOptions = .PrettyPrinted) throws -> NSData? {
//
//        return try NSJSONSerialization.dataWithJSONObject(anyObject, options:JSONWritingOptions)
//    }
    
    var rawString: String? {
        
        if let anyObject = anyObject {
            
            do {
                
                let JSONData = try NSJSONSerialization.dataWithJSONObject(anyObject, options: NSJSONWritingOptions.PrettyPrinted)
                
                let JSONString = String(data: JSONData, encoding: NSUTF8StringEncoding)
//                JSONString = JSONString?.stringByReplacingOccurrencesOfString("\n", withString: "")
//                JSONString = JSONString?.stringByReplacingOccurrencesOfString(" ", withString: "")
                
                return JSONString
            }
            catch { }
        }
        
        return nil
    }
}

// MARK:- subscript

protocol JSONSubscriptable {}

extension String: JSONSubscriptable {}

extension Int: JSONSubscriptable {}

extension SoftJSON {
    
    private subscript(index index: Int) -> SoftJSON? {
        
        get {
            
            switch content {
                
            case ._Array(let array) where array.count > index: return SoftJSON.init(anyObject: array[index])
            default: return nil;
            }
        }
        set {
            
            switch content {
                
            case ._Array(var array) where array.count > index:
                
                if let anObject = newValue?.anyObject {
                
                    array[index] = anObject
                
                    content = ._Array(array)
                }
                else {
                    
                    content = ._Null
                }
                
            case ._Null:
                
                var array = [AnyObject]()
                
                if let anObject = newValue?.anyObject {
                    
                    array[index] = anObject
                    
                    content = ._Array(array)
                }
                else {
                    
                    content = ._Null
                }
                
            default: break;
            }
        }
    }
    
    private subscript(key key: String) -> SoftJSON? {
        
        get {
            
            switch content {
                
            case ._Object(let dictionary): if let anyObject = dictionary[key] { return SoftJSON.init(anyObject: anyObject) } else { return nil }
            default: return nil;
            }
        }
        set {
            
            switch content {
                
            case ._Object(var dictionary):
                
                if let anObject = newValue?.anyObject {
                
                    dictionary[key] = anObject
                
                    content = ._Object(dictionary)
                }
                else {
                    
                    content = ._Null
                }
                
            case ._Null:
                
                var dictionary = [String:AnyObject]()
                
                if let anObject = newValue?.anyObject {
                    
                    dictionary[key] = anObject
                    
                    content = ._Object(dictionary)
                }
                else {
                    
                    content = ._Null
                }
                
            default: break;
            }
        }
    }
    
    private subscript(subscriptable subscriptable: JSONSubscriptable) -> SoftJSON? {
        
        get {
            
            switch subscriptable {
                
            case let index as Int: return self[index: index]
            case let key as String: return self[key: key]
            default: return nil
            }
        }
        set {
            
            switch subscriptable {
                
            case let index as Int: self[index: index] = newValue
            case let key as String: self[key: key] = newValue
            default: break
            }
        }
    }
    
    subscript(subscriptable: JSONSubscriptable) -> SoftJSON? {
        
        get {
            
            return self[subscriptable: subscriptable]
        }
        set {
            
            self[subscriptable: subscriptable] = newValue
        }
    }
    
    subscript(path: [JSONSubscriptable]) -> SoftJSON? {
        
        get {
            
            switch path.count {
                
            case 0: return nil
            default:
                
                var currentTargetJSON = self
                
                for subscriptable in path {
                    
                    if let JSON = currentTargetJSON[subscriptable: subscriptable] {
                        
                        currentTargetJSON =  JSON
                    }
                    else {
                        
                        return nil
                    }
                }
                
                return currentTargetJSON
            }
        }
        set {
            
            switch path.count {
             
            case 0: break
            case 1: self[subscriptable:path[0]] = newValue
            default:
                
                var restPath = path
                restPath.removeFirst()
                
                if var currentTargetJSON = self[subscriptable: path[0]] {
                    
                    currentTargetJSON[restPath] = newValue
                    self[subscriptable: path[0]] = currentTargetJSON
                }
                else {
                    
                    var currentTargetJSON = SoftJSON(anyObject: nil)
                    
                    currentTargetJSON[restPath] = newValue
                    self[subscriptable: path[0]] = currentTargetJSON
                }
            }
        }
    }
}

// MARK:- Safe getters

extension SoftJSON {
    
    func dictionaryValue() -> [String:AnyObject]? {
        
        switch content {

        case ._Object(let dictionary): return dictionary
        default: return nil;
        }
    }
    
    func arrayValue() -> [SoftJSON]? {
        
        switch content {
            
        case ._Array(let array): return array.map() { SoftJSON(anyObject: $0) }
        default: return nil;
        }
    }
    
    func stringValue() -> String? {
        
        switch content {
            
        case ._String(let string): return string
        default: return nil;
        }
    }
    
    func boolValue() -> Bool? {
        
        switch content {
            
        case ._Bool(let bool): return bool
        default: return nil;
        }
    }
    
    func numberValue() -> NSNumber? {
        
        switch content {
            
        case ._Number(let number): return number
        default: return nil;
        }
    }
    
    func intValue() -> Int? {
        
        switch content {
            
        case ._Number(let number): return number.integerValue
        default: return nil;
        }
    }
    
    func unsignedIntValue() -> UInt? {
        
        switch content {
            
        case ._Number(let number): return number.unsignedIntegerValue
        default: return nil;
        }
    }
    
    func floatValue() -> Float? {
        
        switch content {
            
        case ._Number(let number): return number.floatValue
        default: return nil;
        }
    }
    
    func doubleValue() -> Double? {
        
        switch content {
            
        case ._Number(let number): return number.doubleValue
        default: return nil;
        }
    }
}

// MARK:- Safe Setters

extension SoftJSON {
    
    mutating func append(JSON: SoftJSON) -> Bool {
        
        switch (content, JSON.content) {
            
        case (._Object(var selfDictionary), ._Object(let dictionary)):
            
            for (key, value) in dictionary {
                
                selfDictionary[key] = value
            }
            
            content = ._Object(selfDictionary)
            
            return true
        default: return false;
        }
    }
    
    mutating func appendValue(value: AnyObject, forKey: String) -> Bool {
        
        return self.append(SoftJSON(value: value, key: forKey))
    }
}

// MARK:- Printable

extension SoftJSON: CustomStringConvertible, CustomDebugStringConvertible {
    
    var description: String {
        
        if let rawString = rawString {
            
            return rawString
        }
        else {
            
            return "Unknown JSON"
        }
    }
    
    var debugDescription: String {
        
        return description
    }
}

// MARK:- NSNumber extension
extension NSNumber {
    
    class func trueNumber() -> NSNumber {
        
        return NSNumber(bool: true)
    }
    
    class func falseNumber() -> NSNumber {
        
        return NSNumber(bool: false)
    }
    
    var trueObjCType: String? {
        
        return String.fromCString(NSNumber.trueNumber().objCType)
    }
    
    var falseObjCType: String? {
        
        return String.fromCString(NSNumber.falseNumber().objCType)
    }
    
    func isBool() -> Bool {
        
        let objCType = String.fromCString(self.objCType)
        
        if self.compare(NSNumber.trueNumber()) == .OrderedSame && objCType == trueObjCType || self.compare(NSNumber.falseNumber()) == .OrderedSame && objCType == falseObjCType {
            
            return true
        }
        else {
            
            return false
        }
    }
}