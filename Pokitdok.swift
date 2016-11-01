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
    
    struct PokitdokResponse {
        var success: Bool?
        var data: AnyObject?
    }

    let username: String
    let password: String
    let url_base: String
    let token_url: String
    let auth_url: String
    let desired_scope: String?
    let auto_refresh_token: Bool

    var access_token: String? = nil
    var response_success: Bool? = nil
    var response_data: AnyObject? = nil

    init(client_id: String, client_secret: String, base_path: String = "https://platform.pokitdok.com", version: String = "v4", scope: String?, auto_refresh: Bool = false){
        /*
            Initialize necessary variables
        */

        username = client_id
        password = client_secret
        url_base = base_path + "/api/" + version
        token_url = base_path + "/oauth2/token"
        auth_url = base_path + "/oauth2/authorize"
        desired_scope = scope
        auto_refresh_token = auto_refresh
        
        super.init()
        fetch_access_token()
    }

    func fetch_access_token(){
        /*
            Retrieve OAuth2 access token
        */

        let utf8str = "\(username):\(password)".data(using: String.Encoding.utf8)
        let encoded_id_secret = utf8str?.base64EncodedString(options: [])
        let headers = ["Authorization" : "Basic \(encoded_id_secret)"] as Dictionary<String, String>
        let params = ["grant_type" : "client_credentials" as AnyObject] as Dictionary<String, AnyObject>

        let request = prepare_request(path: token_url, method: "POST", headers: headers, params: params, files: nil)
        make_request(request: request)

        if response_success == true {
            access_token = response_data?["access_token"] as! String?
        } else {
            print("Failed to fetch token")
        }
        clean_response_variables()
    }
    
    func request(path: String, method: String = "GET", params: Dictionary<String, AnyObject>? = nil, files: [AnyObject?]?) -> PokitdokResponse {
        /*
            General method for submitting an API request
        */
        
        let request_url = url_base + path
        var auth_headers = ["Authorization" : "Bearer \(access_token)", "Content-Type" : "application/json"] as Dictionary<String, String>

        var request = prepare_request(path: request_url, method: method, headers: auth_headers, params: params, files: files)
        make_request(request: request)

        var resp: PokitdokResponse
        
        if auto_refresh_token, response_success == false, response_data?["errors"] as! String == "TOKEN_EXPIRED" {
            fetch_access_token()
            auth_headers = ["Authorization" : "Bearer \(access_token)", "Content-Type" : "application/json"] as Dictionary<String, String>
            request = prepare_request(path: request_url, method: method, headers: auth_headers, params: params, files: files)
            make_request(request: request)
            resp = PokitdokResponse(success: response_success, data: response_data)
        } else {
            resp = PokitdokResponse(success: response_success, data: response_data)
        }

        clean_response_variables()
        return resp
    }
    
    private func clean_response_variables() -> Void {
        /*
            Set response variables to nil to ensure each request-response is executed independently and cleanly
        */
        response_success = nil
        response_data = nil
    }
    
    private func prepare_request(path: String, method: String = "GET", headers: Dictionary<String, String>? = nil,
                                params: Dictionary<String, AnyObject>? = nil, files: [AnyObject?]?) -> URLRequest{
        /*
            Create NSMutableURLRequest Object (package up request data into object)
        */

        var request = URLRequest(url: NSURL(string: path)! as URL)
        request.httpMethod = method

        if let headers = headers {
            for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        }

        if let params = params {
            if method == "GET" {
                var paramString = ""
                for (key, value) in params {
                    let escapedKey = key.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
                    let escapedValue = value.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
                    paramString += "\(escapedKey)=\(escapedValue)&"
                }
                request.httpBody = paramString.data(using: String.Encoding.utf8)
            } else {
                do {
                    try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
                } catch {
                    print(error)
                }
            }
        }
        
        return request
    }
    
    private func make_request(request: URLRequest) -> Void {
        /*
            Send the request off and return result
        */
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    self.response_success = true
                    self.response_data = json as AnyObject?
                } else if let response = response as? HTTPURLResponse, 401 ~= response.statusCode{
                    self.response_success = true
                    self.response_data = ["errors" : "TOKEN_EXPIRED"] as AnyObject?
                } else {
                    self.response_success = false
                    self.response_data = json as AnyObject?
                }
            }
        })
        task.resume()
    }

    func get(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience GET type method
        */

        return request(path: path, method: "GET", params: params, files: nil)
    }
    
    func put(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience PUT type method
        */

        return request(path: path, method: "PUT", params: params, files: nil)
    }
    
    func post(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience POST type method
        */

        return request(path: path, method: "POST", params: params, files: nil)
    }
    
    func delete(path: String, params: Dictionary<String, AnyObject>? = nil) -> PokitdokResponse {
        /*
            Convenience DELETE type method
        */

        return request(path: path, method: "DELETE", params: params, files: nil)
    }
    
    func activities(activity_id: String?, activities_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Fetch platform activity information
        */

        let path = "/activities/\(activity_id ?? "")"
        let method = "GET"

        return request(path: path, method: method, params: activities_request, files: nil)
    }

    func cash_prices(cash_prices_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Fetch cash price information
        */

        let path = "/prices/cash"
        let method = "GET"

        return request(path: path, method: method, params: cash_prices_request, files: nil)
    }

    func ccd(ccd_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a continuity of care document (CCD) request
        */

        let path = "/ccd/"
        let method = "POST"
        
        return request(path: path, method: method, params: ccd_request, files: nil)
    }

    func claims(claims_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a claims request
        */

        let path = "/claims/"
        let method = "POST"
        
        return request(path: path, method: method, params: claims_request, files: nil)
    }

    func claims_status(claims_status_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a claims status request
        */

        let path = "/claims/status"
        let method = "POST"
        
        return request(path: path, method: method, params: claims_status_request, files: nil)
    }

    func mpc(code: String?, mpc_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Access clinical and consumer friendly information related to medical procedures
        */

        let path = "/mpc/\(code ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: mpc_request, files: nil)
    }

    func icd_convert(code: String) -> PokitdokResponse {
        /*
            Locate the appropriate diagnosis mapping for the specified ICD-9 code
        */

        let path = "/icd/convert/\(code)"
        let method = "GET"
        
        return request(path: path, method: method, params: nil, files: nil)
    }

    func claims_convert(x12_claims_file: AnyObject) -> PokitdokResponse {
        /*
            Submit a raw X12 837 file to convert to a claims API request and map any ICD-9 codes to ICD-10
        */

        let path = "/claims/convert"
        let method = "POST"
        
        return request(path: path, method: method, params: nil, files: [x12_claims_file])
    }

    func eligibility(eligibility_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit an eligibility request
        */

        let path = "/eligibility"
        let method = "POST"
        
        return request(path: path, method: method, params: eligibility_request, files: nil)
    }

    func enrollment(enrollment_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Submit a benefits enrollment/maintenance request
        */

        let path = "/enrollment"
        let method = "POST"
        
        return request(path: path, method: method, params: enrollment_request, files: nil)
    }

    func enrollment_snapshot(trading_partner_id: String, x12_file: AnyObject) -> PokitdokResponse {
        /*
            Submit a X12 834 file to the platform to establish the enrollment information within it
            as the current membership enrollment snapshot for a trading partner
        */

        let path = "/enrollment/snapshot"
        let method = "POST"
        
        return request(path: path, method: method, params: nil, files: [x12_file])
    }

    func enrollment_snapshots(snapshot_id: String?, snapshots_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            List enrollment snapshots that are stored for the client application
        */

        let path = "/enrollment/snapshot/\(snapshot_id ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: snapshots_request, files: nil)
    }

    func enrollment_snapshot_data(snapshot_id: String) -> PokitdokResponse {
        /*
            List enrollment request objects that make up the specified enrollment snapshot
        */

        let path = "/enrollment/snapshot/\(snapshot_id)/data"
        let method = "GET"
        
        return request(path: path, method: method, params: nil, files: nil)
    }

    func insurance_prices(insurance_prices_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Fetch insurance price information
        */

        let path = "/prices/insurance"
        let method = "GET"
        
        return request(path: path, method: method, params: insurance_prices_request, files: nil)
    }

    func payers(payers_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Fetch payer information for supported trading partners
        */

        let path = "/payers/"
        let method = "GET"
        
        return request(path: path, method: method, params: payers_request, files: nil)
    }

    func plans(plans_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Fetch insurance plans information
        */

        let path = "/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: plans_request, files: nil)
    }

    func providers(npi: String?, providers_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Search health care providers in the PokitDok directory
        */

        let path = "/providers/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: providers_request, files: nil)
    }

    func trading_partners(trading_partner_id: String?) -> PokitdokResponse {
        /*
            Search trading partners in the PokitDok Platform
        */

        let path = "/tradingpartners/\(trading_partner_id ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: nil, files: nil)
    }

    func referrals(referral_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Submit a referral request
        */

        let path = "/referrals/"
        let method = "POST"
        
        return request(path: path, method: method, params: referral_request, files: nil)
    }

    func authorizations(authorizations_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Submit an authorization request
        */

        let path = "/authorizations/"
        let method = "POST"
        
        return request(path: path, method: method, params: authorizations_request, files: nil)
    }

    func schedulers(scheduler_uuid: String?) -> PokitdokResponse {
        /*
            Get information about supported scheduling systems or fetch data about a specific scheduling system
        */

        let path = "/schedule/schedulers/\(scheduler_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: nil, files: nil)
    }

    func appointment_types(appointment_type_uuid: String?) -> PokitdokResponse {
        /*
            Get information about appointment types or fetch data about a specific appointment type
        */

        let path = "/schedule/appointmenttypes/\(appointment_type_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: nil, files: nil)
    }

    func schedule_slots(slots_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Submit an open slot for a provider's schedule
        */

        let path = "/schedule/slots/"
        let method = "POST"
        
        return request(path: path, method: method, params: slots_request, files: nil)
    }

    func appointments(appointment_uuid: String?, appointments_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Query for open appointment slots or retrieve information for a specific appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: appointments_request, files: nil)
    }

    func book_appointment(appointment_uuid: String, appointment_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Book an appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointment_request, files: nil)
    }

    func update_appointment(appointment_uuid: String, appointment_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Update an appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointment_request, files: nil)
    }

    func cancel_appointment(appointment_uuid: String) -> PokitdokResponse {
        /*
            Cancel an appointment
        */

        let path = "/schedule/appointments/\(appointment_uuid)"
        let method = "DELETE"
        
        return request(path: path, method: method, params:nil, files: nil)
    }

    func create_identity(identity_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Creates an identity resource
        */

        let path = "/identity/"
        let method = "POST"
        
        return request(path: path, method: method, params: identity_request, files: nil)
    }

    func update_identity(identity_uuid: String, identity_request: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Updates an existing identity resource.
        */

        let path = "/identity/\(identity_uuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: identity_request, files: nil)
    }

    func identity(identity_uuid: String?, identity_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Queries for an existing identity resource by uuid or for multiple resources using parameters.
        */

        let path = "/identity/\(identity_uuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: identity_request, files: nil)
    }

    func identity_history(identity_uuid: String, historical_version: String?) -> PokitdokResponse {
        /*
            Queries for an identity record's history.
        */

        let path = "identity/\(identity_uuid)/history/\(historical_version ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: nil, files: nil)
    }

    func identity_match(identity_match_data: Dictionary<String, AnyObject>) -> PokitdokResponse {
        /*
            Creates an identity match job.
        */

        let path = "/identity/match"
        let method = "POST"
        
        return request(path: path, method: method, params: identity_match_data, files: nil)
    }

    func pharmacy_plans(pharmacy_plans_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Search drug plan information by trading partner and various plan identifiers
        */

        let path = "/pharmacy/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacy_plans_request, files: nil)
    }

    func pharmacy_formulary(pharmacy_formulary_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Search drug plan formulary information to determine if a drug is covered by the specified drug plan.
        */

        let path = "/pharmacy/formulary"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacy_formulary_request, files: nil)
    }

    func pharmacy_network(npi: String?, pharmacy_network_request: Dictionary<String, AnyObject>?) -> PokitdokResponse {
        /*
            Search for in-network pharmacies
        */

        let path = "/pharmacy/network/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacy_network_request, files: nil)
    }

}
