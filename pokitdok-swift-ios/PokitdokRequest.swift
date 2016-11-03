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
    
    var requestObject: URLRequest? = nil
    var responseObject: PokitdokResponse? = nil
    
    init(path: String, method: String = "GET", headers: Dictionary<String, String>? = nil, params: Dictionary<String, Any>? = nil, file_paths: Array<String>? = nil){
        /*
         Make http call
         */
        super.init()
        requestObject = URLRequest(url: NSURL(string: path)! as URL)
        requestObject!.httpMethod = method
        buildRequestHeaders(headers: headers)
        buildRequestBody(path: path, params: params, file_paths: file_paths)
    }
    
    func call() -> PokitdokResponse{
        /*
         Send the request off and return result
         */
        if requestObject != nil {
            let sema = DispatchSemaphore( value: 0 ) // make it real time sync
            let task = URLSession.shared.dataTask(with: requestObject!, completionHandler: { (data, response, error) -> Void in
                self.responseObject = PokitdokResponse(success: false, response: response, data: data, error: error, json: nil, message: nil)
                
                if let data = data {
                    // wrap catch
                    self.responseObject?.json = try! JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>
                }
                if let response = response as? HTTPURLResponse {
                    if 200...299 ~= response.statusCode {
                        self.responseObject?.success = true
                    } else if 401 ~= response.statusCode {
                        self.responseObject?.message = "TOKEN_EXPIRED"
                    }
                }
                sema.signal()
            })
            task.resume()
            sema.wait()
        }
        return self.responseObject ?? PokitdokResponse()
    }
    
    func getHeader(key: String) -> String? {
        if let request = requestObject {
            return request.value(forHTTPHeaderField: key)
        } else {
            return nil
        }
    }
    
    func setHeader(key: String, value: String){
        requestObject!.setValue(value, forHTTPHeaderField: key)
    }
    
    private func buildRequestHeaders(headers: Dictionary<String, String>? = nil){
        /*
         Set the header values on the request
         */
        if requestObject != nil {
            if let headers = headers {
                for (key, value) in headers { setHeader(key: key, value: value) }
            }
        }
    }
    
    private func buildRequestBody(path: String, params: Dictionary<String, Any>? = nil, file_paths: Array<String>? = nil){
        /*
         Create the body of the request
         WORK ON THIS SHIT TO INCLUDE FILES
         */
        if requestObject != nil {
            let contentType = requestObject!.value(forHTTPHeaderField: "Content-Type")
            if let params = params {
                if requestObject!.httpMethod == "GET" {
                    let paramString = buildParamString(params: params)
                    print(paramString)
                    requestObject!.url = NSURL(string: "\(path)?\(paramString)")! as URL
                } else {
                    if contentType == "application/json" {
                        requestObject!.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
                        print(String(data: requestObject!.httpBody!, encoding: String.Encoding.utf8) ?? "")
                    } else if contentType == "application/x-www-form-urlencoded" {
                        let paramString = buildParamString(params: params)
                        print(paramString)
                        requestObject!.httpBody = paramString.data(using: .utf8)
                    }
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
}
