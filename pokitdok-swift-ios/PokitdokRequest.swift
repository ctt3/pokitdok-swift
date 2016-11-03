//
//  APIRequest.swift
//  pokitdok-swift-ios
//
//  Created by Charlie Thiry on 11/3/16.
//  Copyright © 2016 Charlie Thiry. All rights reserved.
//

import Foundation

public struct PokitdokResponse {
    var success: Bool? = false
    var response: URLResponse? = nil
    var data: Data? = nil
    var error: Error? = nil
    var json: Dictionary<String, Any>? = nil
    var message: String? = nil
}

public class PokitdokRequest: NSObject {

    var requestObject: URLRequest
    var responseObject: PokitdokResponse
    
    init(path: String, method: String = "GET", headers: Dictionary<String, String>? = nil, params: Dictionary<String, Any>? = nil, file_paths: Array<String>? = nil){
        /*
            Initialize requestObject variables
        */
        requestObject = URLRequest(url: NSURL(string: path)! as URL)
        responseObject = PokitdokResponse()
        super.init()

        requestObject.httpMethod = method
        buildRequestHeaders(headers: headers)
        buildRequestBody(path: path, params: params, file_paths: file_paths)
    }
    
    func call() -> PokitdokResponse{
        /*
            Send the request off and return result
        */
        let sema = DispatchSemaphore( value: 0 ) // make it real time sync
        let task = URLSession.shared.dataTask(with: requestObject, completionHandler: { (data, response, error) -> Void in
            self.responseObject.response = response
            self.responseObject.data = data
            self.responseObject.error = error
                
            if let data = data {
                // wrap catch
                self.responseObject.json = try! JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>
            }
            if let response = response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    self.responseObject.success = true
                } else if 401 ~= response.statusCode {
                    self.responseObject.message = "TOKEN_EXPIRED"
                }
            }
            sema.signal()
        })
        task.resume()
        sema.wait()
        return responseObject
    }
    
    private func buildRequestHeaders(headers: Dictionary<String, String>? = nil){
        /*
            Set the header values on the request
        */
        if let headers = headers {
            for (key, value) in headers { setHeader(key: key, value: value) }
        }
    }
    
    private func buildRequestBody(path: String, params: Dictionary<String, Any>? = nil, file_paths: Array<String>? = nil){
        /*
            Create the body of the request
            WORK ON THIS SHIT TO INCLUDE FILE TRANSMISSION
        */
        let contentType = getHeader(key: "Content-Type")
        if let params = params {
            if requestObject.httpMethod == "GET" {
                let paramString = buildParamString(params: params)
                print(paramString)
                requestObject.url = NSURL(string: "\(path)?\(paramString)")! as URL
            } else {
                if contentType == "application/json" {
                    requestObject.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
                    print(String(data: requestObject.httpBody!, encoding: String.Encoding.utf8) ?? "")
                } else if contentType == "application/x-www-form-urlencoded" {
                    let paramString = buildParamString(params: params)
                    print(paramString)
                    requestObject.httpBody = paramString.data(using: .utf8)
                }
            }
        }
    }
    
    private func buildParamString(params: Dictionary<String, Any>) -> String{
        /*
            Create a url safe parameter string based on a dictionary of key:values
            WORK ON THIS SHIT
        */
        var pcs = [String]()
        for (key, value) in params {
            var valStr = ""
            if let value = value as? String {
                valStr = value
            } else if let value = value as? Dictionary<String, Any> {
                valStr = buildParamString(params: value)
            } else if let value = value as? Array<String> {
                valStr = value.joined(separator: ",")
            }
            let escapedKey = key.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            let escapedValue = valStr.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            pcs.append("\(escapedKey ?? "")=\(escapedValue ?? "")")
        }
        return pcs.joined(separator: "&")
    }
    
    func getHeader(key: String) -> String? {
        /*
            Enables user to manipulate headers from outside the class
            return the header at the key from the requestObject
        */
        return requestObject.value(forHTTPHeaderField: key)
    }
    
    func setHeader(key: String, value: String){
        /*
            Enables user to manipulate headers from outside the class
            set the header to the key: value pair
        */
        requestObject.setValue(value, forHTTPHeaderField: key)
    }
    
    func getMethod() -> String? {
        return requestObject.httpMethod
    }

    func setMethod(method: String){
        requestObject.httpMethod = method
    }

    func getPath() -> String? {
        return requestObject.url?.absoluteString
    }

    func setPath(path: String) {
        requestObject.url = NSURL(string: path)! as URL
    }
}
