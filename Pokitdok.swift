//
//  Pokitdok.swift
//  pokitdok-swift-ios
//
//  Created by Charlie Thiry on 10/28/16.
//  Copyright © 2016 Charlie Thiry. All rights reserved.
//

import UIKit
import Foundation

extension Dictionary {
    func toJSONString() -> String {
        // WORK ON THIS
        var pcs = [String]()
        for (key, val) in self {
            var valStr = ""
            if let val = val as? String {
                valStr = "\"\(val)\""
            } else if let val = val as? Dictionary<String, AnyObject> {
                valStr = val.toJSONString() // recursion for nested dictionaries
            } else if let val = val as? Array<String> {
                let tmpStr = val.joined(separator: "\",\"")
                valStr = "[\"\(tmpStr)\"]"
            } else if let val = val as? NSNumber {
                valStr = "\(val)"
            }
            pcs.append("\"\(key)\":\(valStr)")
        }
        return "{" + pcs.joined(separator: ",") + "}"
    }
    
    func toParamString() -> String {
        // WORK ON THIS
        var pcs = [String]()
        for (key, value) in self {
            var valStr = ""
            if let value = value as? String {
                valStr = value
            } else if let value = value as? Dictionary<String, AnyObject> {
                valStr = value.toParamString()
            } else if let value = value as? Array<String> {
                valStr = value.joined(separator: ",")
            }
            let escapedKey = (key as! String).addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            let escapedValue = valStr.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            pcs.append("\(escapedKey ?? "")=\(escapedValue ?? "")")
        }
        return pcs.joined(separator: "&")
    }
}

class Pokitdok: NSObject {
    /*
        Swift client to send requests to Pokitdok Platform APIs
    */

    struct PokitdokResponse {
        var success: Bool?
        var data: AnyObject?
    }

    let username: String
    let password: String
    let urlBase: String
    let tokenUrl: String
    let authUrl: String
    let desiredScope: String?
    let autoRefreshToken: Bool

    var accessToken: String? = nil
    var responseSuccess: Bool? = nil
    var responseData: AnyObject? = nil

    init(clientId: String, clientSecret: String, basePath: String = "https://platform.pokitdok.com", version: String = "v4", scope: String? = nil, autoRefresh: Bool = false){
        /*
            Initialize necessary variables
        */

        username = clientId
        password = clientSecret
        urlBase = basePath + "/api/" + version
        tokenUrl = basePath + "/oauth2/token"
        authUrl = basePath + "/oauth2/authorize"
        desiredScope = scope
        autoRefreshToken = autoRefresh
        
        super.init()
        fetchAccessToken()
    }

    func fetchAccessToken(){
        /*
            Retrieve OAuth2 access token
        */

        let utf8str = "\(username):\(password)".data(using: String.Encoding.utf8)
        let encodedIdSecret = utf8str?.base64EncodedString(options: [])
        let headers = ["Authorization" : "Basic \(encodedIdSecret ?? "")", "Content-Type" : "application/x-www-form-urlencoded"] as Dictionary<String, String>
//        let headers = ["Authorization" : "Basic \(encoded_id_secret ?? "")", "Content-Type" : "application/json"] as Dictionary<String, String>
        let params = ["grant_type" : "client_credentials"] as Dictionary<String, Any>

//        let test_url = "http://localhost:5002/swift-test"
        let request = prepareRequest(path: tokenUrl, method: "POST", headers: headers, params: params)
        
        makeRequest(request: request)

        if self.responseSuccess == true {
            self.accessToken = self.responseData?["access_token"] as! String?
        } else {
            print("Failed to fetch token")
        }
        cleanResponseVariables()
        print("\(self.responseSuccess)")
        print("\(accessToken)")
    }
    
    func request(path: String, method: String = "GET", params: Dictionary<String, Any>? = nil, files: [AnyObject?]? = nil) -> PokitdokResponse {
        /*
            General method for submitting an API request
        */
        
        let requestUrl = urlBase + path
        var authHeaders = ["Authorization" : "Bearer \(accessToken ?? "")", "Content-Type" : "application/json"] as Dictionary<String, String>

        var request = prepareRequest(path: requestUrl, method: method, headers: authHeaders, params: params, files: files)
        makeRequest(request: request)

        var resp: PokitdokResponse
        
        if autoRefreshToken, responseSuccess == false, responseData?["errors"] as! String == "TOKEN_EXPIRED" {
            fetchAccessToken()
            authHeaders = ["Authorization" : "Bearer \(accessToken ?? "")", "Content-Type" : "application/json"] as Dictionary<String, String>
            request = prepareRequest(path: requestUrl, method: method, headers: authHeaders, params: params, files: files)
            makeRequest(request: request)
            resp = PokitdokResponse(success: responseSuccess, data: responseData)
        } else {
            resp = PokitdokResponse(success: responseSuccess, data: responseData)
        }

        cleanResponseVariables()
        return resp
    }
    
    private func cleanResponseVariables() -> Void {
        /*
            Set response variables to nil to ensure each request-response is executed independently and cleanly
        */
        responseSuccess = nil
        responseData = nil
    }
    
    private func prepareRequest(path: String, method: String = "GET", headers: Dictionary<String, String>? = nil,
                                params: Dictionary<String, Any>? = nil, files: [AnyObject?]? = nil) -> URLRequest{
        /*
            Create NSMutableURLRequest Object (package up request data into object)
        */
        print("prepare_request")
        print("path: \(path)")
        print("method: \(method)")
        var request = URLRequest(url: NSURL(string: path)! as URL)
        request.httpMethod = method

        if var headers = headers {
            if headers["Content-Type"] == nil { headers["Content-Type"] = "application/json" }
        } else {
            var headers = ["Content-Type" : "application/json"]
        }
        let contentType = headers?["Content-Type"]
        for (key, value) in headers! { request.setValue(value, forHTTPHeaderField: key) }

        if let params = params {
            if contentType == "application/json" {
                let paramString = params.toJSONString()
                print(paramString)
                request.httpBody = paramString.data(using: .utf8)
            } else if contentType == "application/x-www-form-urlencoded" {
                let paramString = params.toParamString()
                print(paramString)
                request.httpBody = paramString.data(using: .utf8)
            }
        }

//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: params!, options: [])
//            print(String(data: request.httpBody!, encoding: String.Encoding.utf8))
//        } catch {
//            print(error)
//        }

        
        return request
    }

    private func makeRequest(request: URLRequest) -> Void {
        /*
            Send the request off and return result
        */
        let sema = DispatchSemaphore( value: 0 ) // make it real time sync
        print("make_request")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                print((response as? HTTPURLResponse)?.statusCode  ?? "NONE")
                print(String(data: data, encoding: String.Encoding.utf8) ?? "NONE")
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    self.responseSuccess = true
                    self.responseData = json as AnyObject?
                } else if let response = response as? HTTPURLResponse, 401 ~= response.statusCode{
                    self.responseSuccess = false
                    self.responseData = ["errors" : "TOKEN_EXPIRED"] as AnyObject?
                } else {
                    self.responseSuccess = false
                    self.responseData = json as AnyObject?
                }
                print("Response Success: \(self.responseSuccess!)")
                print("Access Token: \(self.responseData?["access_token"] as! String? ?? "None")")
            }
            sema.signal()
        })
        task.resume()
        sema.wait()
    }


    func get(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience GET type method
        */

        return request(path: path, method: "GET", params: params)
    }
    
    func put(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience PUT type method
        */

        return request(path: path, method: "PUT", params: params)
    }
    
    func post(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience POST type method
        */

        return request(path: path, method: "POST", params: params)
    }
    
    func delete(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience DELETE type method
        */

        return request(path: path, method: "DELETE", params: params)
    }
    
    func activities(activityId: String? = nil, activitiesRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Fetch platform activity information
        */

        let path = "/activities/\(activityId ?? "")"
        let method = "GET"

        return request(path: path, method: method, params: activitiesRequest)
    }

    func cashPrices(cashPricesRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Fetch cash price information
        */

        let path = "/prices/cash"
        let method = "GET"

        return request(path: path, method: method, params: cashPricesRequest)
    }

    func ccd(ccdRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a continuity of care document (CCD) request
        */

        let path = "/ccd/"
        let method = "POST"
        
        return request(path: path, method: method, params: ccdRequest)
    }

    func claims(claimsRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a claims request
        */

        let path = "/claims/"
        let method = "POST"
        
        return request(path: path, method: method, params: claimsRequest)
    }

    func claimsStatus(claimsStatusRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a claims status request
        */

        let path = "/claims/status"
        let method = "POST"
        
        return request(path: path, method: method, params: claimsStatusRequest)
    }

    func mpc(code: String? = nil, mpcRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Access clinical and consumer friendly information related to medical procedures
        */

        let path = "/mpc/\(code ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: mpcRequest)
    }

    func icdConvert(code: String) -> PokitdokResponse {
        /*
            Locate the appropriate diagnosis mapping for the specified ICD-9 code
        */

        let path = "/icd/convert/\(code)"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func claimsConvert(x12ClaimsFile: AnyObject) -> PokitdokResponse {
        /*
            Submit a raw X12 837 file to convert to a claims API request and map any ICD-9 codes to ICD-10
        */

        let path = "/claims/convert"
        let method = "POST"
        
        return request(path: path, method: method, files: [x12ClaimsFile])
    }

    func eligibility(eligibilityRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit an eligibility request
        */

        let path = "/eligibility"
        let method = "POST"
        
        return request(path: path, method: method, params: eligibilityRequest)
    }

    func enrollment(enrollmentRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a benefits enrollment/maintenance request
        */

        let path = "/enrollment"
        let method = "POST"
        
        return request(path: path, method: method, params: enrollmentRequest)
    }

    func enrollmentSnapshot(tradingPartnerId: String, x12File: AnyObject) -> PokitdokResponse {
        /*
            Submit a X12 834 file to the platform to establish the enrollment information within it
            as the current membership enrollment snapshot for a trading partner
        */

        let path = "/enrollment/snapshot"
        let method = "POST"
        
        return request(path: path, method: method, files: [x12File])
    }

    func enrollmentSnapshots(snapshotId: String? = nil, snapshotsRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            List enrollment snapshots that are stored for the client application
        */

        let path = "/enrollment/snapshot/\(snapshotId ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: snapshotsRequest)
    }

    func enrollmentSnapshotData(snapshotId: String) -> PokitdokResponse {
        /*
            List enrollment request objects that make up the specified enrollment snapshot
        */

        let path = "/enrollment/snapshot/\(snapshotId)/data"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func insurancePrices(insurancePricesRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Fetch insurance price information
        */

        let path = "/prices/insurance"
        let method = "GET"
        
        return request(path: path, method: method, params: insurancePricesRequest)
    }

    func payers(payersRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Fetch payer information for supported trading partners
        */

        let path = "/payers/"
        let method = "GET"
        
        return request(path: path, method: method, params: payersRequest)
    }

    func plans(plansRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Fetch insurance plans information
        */

        let path = "/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: plansRequest)
    }

    func providers(npi: String? = nil, providersRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Search health care providers in the PokitDok directory
        */

        let path = "/providers/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: providersRequest)
    }

    func tradingPartners(tradingPartnerId: String? = nil) -> PokitdokResponse {
        /*
            Search trading partners in the PokitDok Platform
        */

        let path = "/tradingpartners/\(tradingPartnerId ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func referrals(referralRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Submit a referral request
        */

        let path = "/referrals/"
        let method = "POST"
        
        return request(path: path, method: method, params: referralRequest)
    }

    func authorizations(authorizationsRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Submit an authorization request
        */

        let path = "/authorizations/"
        let method = "POST"
        
        return request(path: path, method: method, params: authorizationsRequest)
    }

    func schedulers(schedulerUuid: String? = nil) -> PokitdokResponse {
        /*
            Get information about supported scheduling systems or fetch data about a specific scheduling system
        */

        let path = "/schedule/schedulers/\(schedulerUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func appointmentTypes(appointmentTypeUuid: String? = nil) -> PokitdokResponse {
        /*
            Get information about appointment types or fetch data about a specific appointment type
        */

        let path = "/schedule/appointmenttypes/\(appointmentTypeUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func scheduleSlots(slotsRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Submit an open slot for a provider's schedule
        */

        let path = "/schedule/slots/"
        let method = "POST"
        
        return request(path: path, method: method, params: slotsRequest)
    }

    func appointments(appointmentUuid: String? = nil, appointmentsRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Query for open appointment slots or retrieve information for a specific appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: appointmentsRequest)
    }

    func bookAppointment(appointmentUuid: String, appointmentRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Book an appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointmentRequest)
    }

    func updateAppointment(appointmentUuid: String, appointmentRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Update an appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointmentRequest)
    }

    func cancelAppointment(appointmentUuid: String) -> PokitdokResponse {
        /*
            Cancel an appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid)"
        let method = "DELETE"
        
        return request(path: path, method: method)
    }

    func createIdentity(identityRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Creates an identity resource
        */

        let path = "/identity/"
        let method = "POST"
        
        return request(path: path, method: method, params: identityRequest)
    }

    func updateIdentity(identityUuid: String, identityRequest: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Updates an existing identity resource.
        */

        let path = "/identity/\(identityUuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: identityRequest)
    }

    func identity(identityUuid: String? = nil, identityRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Queries for an existing identity resource by uuid or for multiple resources using parameters.
        */

        let path = "/identity/\(identityUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: identityRequest)
    }

    func identityHistory(identityUuid: String, historicalVersion: String? = nil) -> PokitdokResponse {
        /*
            Queries for an identity record's history.
        */

        let path = "identity/\(identityUuid)/history/\(historicalVersion ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func identityMatch(identityMatchData: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Creates an identity match job.
        */

        let path = "/identity/match"
        let method = "POST"
        
        return request(path: path, method: method, params: identityMatchData)
    }

    func pharmacyPlans(pharmacyPlansRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Search drug plan information by trading partner and various plan identifiers
        */

        let path = "/pharmacy/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacyPlansRequest)
    }

    func pharmacyFormulary(pharmacyFormularyRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Search drug plan formulary information to determine if a drug is covered by the specified drug plan.
        */

        let path = "/pharmacy/formulary"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacyFormularyRequest)
    }

    func pharmacyNetwork(npi: String? = nil, pharmacyNetworkRequest: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Search for in-network pharmacies
        */

        let path = "/pharmacy/network/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacyNetworkRequest)
    }

}
