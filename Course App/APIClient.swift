//
//  APIClient.swift
//  Course App
//
//  Created by Ming Ying on 7/17/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import Foundation

open class APIClient {
    fileprivate var baseURL = ""
    fileprivate var session = URLSession(configuration: URLSessionConfiguration.default)
    
    public init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    fileprivate func requestFor(_ path: String,
                            throughMethod method: String,
                            withBody body:AnyObject?) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = method
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body!, options: JSONSerialization.WritingOptions(rawValue: 0))
        }
        return request
    }
    
    open func post(_ path: String, json: AnyObject?, completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        let request = requestFor(path, throughMethod: "POST", withBody: json)
        dataTask(request, completion: completion)
    }
    
    open func put(_ path: String, json: AnyObject?, completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        let request = requestFor(path, throughMethod: "PUT", withBody: json)
        dataTask(request, completion: completion)
    }
    
    open func get(_ path: String, completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        let request = requestFor(path, throughMethod: "GET", withBody: nil)
        dataTask(request, completion: completion)
    }
    
    open func delete(_ path: String, completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        let request = requestFor(path, throughMethod: "DELETE", withBody: nil)
        dataTask(request, completion: completion)
    }
    
    fileprivate func dataTask(_ request: NSMutableURLRequest, completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
        session.dataTask(with: request as URLRequest , completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    completion(true,json as AnyObject)
                } else {
                    completion(false, json as AnyObject)
                }
            }
            }) .resume()
    }
}
