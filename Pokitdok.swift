//
//  Pokitdok.swift
//  pokitdok-swift-ios
//
//  Created by Charlie Thiry on 10/28/16.
//  Copyright © 2016 Charlie Thiry. All rights reserved.
//

import UIKit
import Foundation

class Pokitdok: NSObject {
    /*
        Swift client to send requests to Pokitdok Platform APIs
    */

    var access_token: String?;

    init(client_id: String, client_secret: String, base_path: String = "https://platform.pokitdok.com", version: String = "v4", scope: String?, auto_refresh: String = false){
        /*
            Initialize necessary variables
        */

        let username = client_id
        let password = client_secret
        let url_base = base_path + "/api/" + version
        let token_url = base_path + "/oauth2/token"
        let auth_url = base_path + "/oauth2/authorize"

        fetch_access_token()
    }

    mutating func fetch_access_token(){
        /*
            Retrieve OAuth2 access token
        */

        let utf8str = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)
        let encoded_id_secret = utf8str?.base64EncodedStringWithOptions([])
        var headers = ["Authorization" : "Basic \(encoded_id_secret)"] as Dictionary<String, String>
        var params = ["grant_type" : "client_credentials"] as Dictionary<String, String>

        let request = prepare_request(token_url, "POST", params)
        let response = make_request(request)

        access_token = response["object"]["access_token"]
    }
    
    func request(path: String, method: String = "GET", params: Dictionary<String, AnyObject>? = nil, files: AnyObject?){
        /*
            General method for submitting an API request
        */
        
        let request_url = url_base + path
        let auth_headers = ["Authorization" : "Bearer \(access_token)", "Content-Type" : "application/json"] as Dictionary<String, String>

        let request = prepare_request(path: request_url, method: method, headers: auth_headers, params: params, files: files)
        let response = make_request(request)

        if response["success"] == false, response["object"] == "TOKEN_EXPIRED" {
            fetch_access_token()
            let auth_headers = ["Authorization" : "Bearer \(access_token)", "Content-Type" : "application/json"] as Dictionary<String, String>
            let request = prepare_request(path: request_url, method: method, headers: auth_headers, params: params, files: files)
            return make_request(request)
        } else {
            return response
        }
    }
    
    private func prepare_request(path: String, method: String = "GET", headers: Dictionary<String, String>? = nil,
                                params: Dictionary<String, AnyObject>? = nil, files: AnyObject?){
        /*
            Create NSMutableURLRequest Object (package up request data into object)
        */

        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        request.HTTPMethod = method

        if let headers = headers {
            for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        }

        if let params = params {
            if method == "GET" {
                var paramString = ""
                for (key, value) in params {
                    let escapedKey = key.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
                    let escapedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
                    paramString += "\(escapedKey)=\(escapedValue)&"
                }
                request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
            } else {
                request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil)
            }
        }
        
        return request
    }
    
    private func make_request(request: NSMutableURLRequest, completion: (_ success: Bool, _ object: AnyObject?) -> ()){
        /*
            Send the request off and return result
        */

        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let data = data {
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let response = response as? NSHTTPURLResponse, 200...299 ~= response.statusCode {
                    return completion(success: true, object: json)
                } else if let response = response as? NSHTTPURLResponse, 401 == response.statusCode{
                    return completion(success: false, object: "TOKEN_EXPIRED")
                } else {
                    return completion(success: false, object: json)
                }
            }
        }
        task.resume()
    }

    // *********
    func post(path: String, params: Dictionary<String, AnyObject>? = nil) {
        request(path, "POST", params){ (success: Bool, json: AnyObject?)
            return json
        }
    }
    // *********
    
    func activities(activity_id: String?, activities_request: AnyObject?){
        /*
            Fetch platform activity information
        */

        let path = "/activities/\(activity_id ?? "")"
        let method = "GET"

        return request(path: path, method: method, params: activities_request)
    }

    func cash_prices(cash_prices_request: AnyObject?){
        /*
            Fetch cash price information
        */

        let path = "/prices/cash"
        let method = "GET"

        return request(path: path, method: method, params: cash_prices_request)
    }

    func ccd(ccd_request: AnyObject){
        /*
            Submit a continuity of care document (CCD) request
        */

        let path = "/ccd/"
        let method = "POST"
        
        return request(path: path, method: method, params: ccd_request)
    }

    func claims(claims_request: AnyObject){
        /*
            Submit a claims request
        */

        let path = "/claims/"
        let method = "POST"
        
        return request(path: path, method: method, params: claims_request)
    }

    func claims_status(claims_status_request: AnyObject){
        /*
            Submit a claims status request
        */

        let path = "/claims/status"
        let method = "POST"
        
        return request(path: path, method: method, params: claims_status_request)
    }

    func mpc(code: String?, mpc_request: AnyObject?){
        /*
            Access clinical and consumer friendly information related to medical procedures
        */

        let path = "/mpc/\(code ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: mpc_request)
    }

    func icd_convert(code: String){
        /*
            Locate the appropriate diagnosis mapping for the specified ICD-9 code
        */

        let path = "/icd/convert/\(code ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func claims_convert(x12_claims_file: AnyObject){
        /*
            Submit a raw X12 837 file to convert to a claims API request and map any ICD-9 codes to ICD-10
        */

        let path = "/claims/convert"
        let method = "POST"
        
        return request(path: path, method: method, files: [x12_claims_file])
    }

    func eligibility(eligibility_request: AnyObject){
        /*
            Submit an eligibility request
        */

        let path = "/eligibility"
        let method = "POST"
        
        return request(path: path, method: method, params: eligibility_request)
    }

    func enrollment(enrollment_request: AnyObject){
        /*
            Submit a benefits enrollment/maintenance request
        */

        let path = "/enrollment"
        let method = "POST"
        
        return request(path: path, method: method, params: enrollment_request)
    }

    func enrollment_snapshot(trading_partner_id: String, x12_file: AnyObject){
        /*
            Submit a X12 834 file to the platform to establish the enrollment information within it
            as the current membership enrollment snapshot for a trading partner
        */

        let path = "/enrollment/snapshot"
        let method = "POST"
        
        return request(path: path, method: method, files: [x12_file])
    }

    func enrollment_snapshots(snapshot_id: String?, snapshots_request: AnyObject?){
        /*
            List enrollment snapshots that are stored for the client application
        */

        let path = "/enrollment/snapshot/\(snapshot_id ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: snapshots_request)
    }

    func enrollment_snapshot_data(snapshot_id: String){
        /*
            List enrollment request objects that make up the specified enrollment snapshot
        */

        let path = "/enrollment/snapshot/\(snapshot_id)/data"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func insurance_prices(insurance_prices_request: AnyObject?){
        /*
            Fetch insurance price information
        */

        let path = "/prices/insurance"
        let method = "GET"
        
        return request(path: path, method: method, params: insurance_prices_request)
    }

    func payers(payers_request: AnyObject?){
        /*
            Fetch payer information for supported trading partners
        */

        let path = "/payers/"
        let method = "GET"
        
        return request(path: path, method: method, params: payers_request)
    }

    func plans(plans_request: AnyObject?){
        /*
            Fetch insurance plans information
        */

        let path = "/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: plans_request)
    }

    func providers(npi: String?, providers_request: AnyObject?){
        /*
            Search health care providers in the PokitDok directory
        */

        let path = "/providers/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: providers_request)
    }

    func trading_partners(trading_partner_id: String?){
        /*
            Search trading partners in the PokitDok Platform
        */

        let path = "/tradingpartners/\(trading_partner_id ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func referrals(referral_request: AnyObject?){
        /*
            Submit a referral request
        */

        let path = "/referrals/"
        let method = "POST"
        
        return request(path: path, method: method, params: referral_request)
    }

    func authorizations(authorizations_request: AnyObject?){
        /*
            Submit an authorization request
        */

        let path = "/authorizations/"
        let method = "POST"
        
        return request(path: path, method: method, params: authorizations_request)
    }

    func schedulers(scheduler_uuid: String?){
        /*
            Get information about supported scheduling systems or fetch data about a specific scheduling system
        */

        let path = "/schedule/schedulers/\(scheduler_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func appointment_types(appointment_type_uuid: String?){
        /*
            Get information about appointment types or fetch data about a specific appointment type
        */

        let path = "/schedule/appointmenttypes/\(appointment_type_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func schedule_slots(slots_request: AnyObject?){
        /*
            Submit an open slot for a provider's schedule
        */

        let path = "/schedule/slots/"
        let method = "POST"
        
        return request(path: path, method: method, params: slots_request)
    }

    func appointments(appointment_uuid: String?, appointments_request: AnyObject?){
        /*
            Query for open appointment slots or retrieve information for a specific appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: appointments_request)
    }

    func book_appointment(appointment_uuid: String, appointment_request: AnyObject){
        /*
            Book an appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid ?? "")"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointment_request)
    }

    func update_appointment(appointment_uuid: String, appointment_request: AnyObject){
        /*
            Update an appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid ?? "")"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointment_request)
    }

    func cancel_appointment(appointment_uuid: String){
        /*
            Cancel an appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid)"
        let method = "DELETE"
        
        return request(path: path, method: method)
    }

    func create_identity(identity_request: AnyObject){
        /*
            Creates an identity resource
        */

        let path = "/identity/"
        let method = "POST"
        
        return request(path: path, method: method, params: identity_request)
    }

    func update_identity(identity_uuid: String, identity_request: AnyObject){
        /*
            Updates an existing identity resource.
        */

        let path = "/identity/\(identity_uuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: identity_request)
    }

    func identity(identity_uuid: String?, identity_request: AnyObject?){
        /*
            Queries for an existing identity resource by uuid or for multiple resources using parameters.
        */

        let path = "/identity/\(identity_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: identity_request)
    }

    func identity_history(identity_uuid: String, historical_version: String?){
        /*
            Queries for an identity record's history.
        */

        let path = "identity/\(identity_uuid)/history/\(historical_version ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func identity_match(identity_match_data: AnyObject){
        /*
            Creates an identity match job.
        */

        let path = "/identity/match"
        let method = "POST"
        
        return request(path: path, method: method, params: identity_match_data)
    }

    func pharmacy_plans(pharmacy_plans_request: AnyObject?){
        /*
            Search drug plan information by trading partner and various plan identifiers
        */

        let path = "/pharmacy/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacy_plans_request)
    }

    func pharmacy_formulary(pharmacy_formulary_request: AnyObject?){
        /*
            Search drug plan formulary information to determine if a drug is covered by the specified drug plan.
        */

        let path = "/pharmacy/formulary"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacy_formulary_request)
    }

    func pharmacy_network(npi: String?, pharmacy_network_request: AnyObject?){
        /*
            Search for in-network pharmacies
        */

        let path = "/pharmacy/network/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacy_network_request)
    }

}
