//
//  APIRequest.swift
//  pokitdok-swift
//
// Copyright (C) 2016, All Rights Reserved, PokitDok, Inc.
// https://www.pokitdok.com
//
// Please see the License.txt file for more information.
// All other rights reserved.
//

import Foundation


class Pokitdok: NSObject {
    /*
        Swift client to send requests to Pokitdok Platform APIs
    */

    let username: String
    let password: String
    let urlBase: String
    let tokenUrl: String
    let authUrl: String
    let redirectURI: String?
    let desiredScope: String?
    let autoRefreshToken: Bool
    let tokenCallback: String?
    let authCode: String?

    var accessToken: String? = nil
    
    let test_url = "http://localhost:5002/swift-test"

    init(clientId: String, clientSecret: String, basePath: String = "https://platform.pokitdok.com", version: String = "v4",
         redirectUri: String? = nil, scope: String? = nil, autoRefresh: Bool = false, tokenRefreshCallback: String? = nil,
         code: String? = nil, token: String? = nil){
        /*
            Initialize necessary variables
        */

        username = clientId
        password = clientSecret
        urlBase = basePath + "/api/" + version
        tokenUrl = basePath + "/oauth2/token"
        authUrl = basePath + "/oauth2/authorize"
        redirectURI = redirectUri
        desiredScope = scope
        autoRefreshToken = autoRefresh
        tokenCallback = tokenRefreshCallback
        authCode = code
        accessToken = token

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
        let params = ["grant_type" : "client_credentials"] as Dictionary<String, Any>

        let tokenResponse = PokitdokRequest(path: tokenUrl, method: "POST", headers: headers, params: params).call()

        if tokenResponse.success == true {
            self.accessToken = tokenResponse.json?["access_token"] as! String?
        } else {
            // raise here
            print("Failed to fetch token")
        }
    }
    
    func request(path: String, method: String = "GET", params: Dictionary<String, Any>? = nil, files: Array<FileData>? = nil) -> Dictionary<String, Any> {
        /*
            General method for submitting an API request
        */
        
        let requestUrl = urlBase + path
        var headers = ["Content-Type": "application/json"]
        headers["Authorization"] = "Bearer \(accessToken ?? "")"

        let requestObject = PokitdokRequest(path: requestUrl, method: method, headers: headers, params: params, files: files)
        var responseObject = requestObject.call()

        if autoRefreshToken, responseObject.success == false, responseObject.message == "TOKEN_EXPIRED" {
            fetchAccessToken()
            requestObject.setHeader(key: "Authorization", value: "Bearer \(accessToken ?? "")")
            responseObject = requestObject.call()
        }

        return responseObject.json ?? [:]
    }

    func get(path: String, params: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Convenience GET type method
        */

        return request(path: path, method: "GET", params: params)
    }
    
    func put(path: String, params: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Convenience PUT type method
        */

        return request(path: path, method: "PUT", params: params)
    }
    
    func post(path: String, params: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Convenience POST type method
        */

        return request(path: path, method: "POST", params: params)
    }
    
    func delete(path: String, params: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Convenience DELETE type method
        */

        return request(path: path, method: "DELETE", params: params)
    }
    
    func activities(activityId: String? = nil, activitiesRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Fetch platform activity information
        */

        let path = "/activities/\(activityId ?? "")"
        let method = "GET"

        return request(path: path, method: method, params: activitiesRequest)
    }
    
    func authorizations(authorizationsRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Submit an authorization request
        */
        
        let path = "/authorizations/"
        let method = "POST"
        
        return request(path: path, method: method, params: authorizationsRequest)
    }

    func cashPrices(cptCode: String, zipCode: String) -> Dictionary<String, Any> {
        /*
            Fetch cash price information
        */

        let path = "/prices/cash"
        let method = "GET"
        let cashPricesRequest = ["cpt_code": cptCode, "zip_code" : zipCode]

        return request(path: path, method: method, params: cashPricesRequest)
    }

    func ccd(ccdRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Submit a continuity of care document (CCD) request
        */

        let path = "/ccd/"
        let method = "POST"
        
        return request(path: path, method: method, params: ccdRequest)
    }

    func claims(claimsRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Submit a claims request
        */

        let path = "/claims/"
        let method = "POST"
        
        return request(path: path, method: method, params: claimsRequest)
    }

    func claimsStatus(claimsStatusRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Submit a claims status request
        */

        let path = "/claims/status"
        let method = "POST"
        
        return request(path: path, method: method, params: claimsStatusRequest)
    }

    func claimsConvert(x12ClaimsFilePath: String) -> Dictionary<String, Any> {
        /*
            Submit a raw X12 837 file to convert to a claims API request and map any ICD-9 codes to ICD-10
        */

        let path = "/claims/convert"
        let method = "POST"
        let file = FileData(path: x12ClaimsFilePath, contentType: "application/EDI-X12")

        return request(path: path, method: method, files: [file])
    }

    func eligibility(eligibilityRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
         Submit an eligibility request
         */
        
        let path = "/eligibility/"
        let method = "POST"
        
        return request(path: path, method: method, params: eligibilityRequest)
    }
    
    func enrollment(enrollmentRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
         Submit a benefits enrollment/maintenance request
         */
        
        let path = "/enrollment"
        let method = "POST"
        
        return request(path: path, method: method, params: enrollmentRequest)
    }
    
    func enrollmentSnapshot(tradingPartnerId: String, x12FilePath: String) -> Dictionary<String, Any> {
        /*
         Submit a X12 834 file to the platform to establish the enrollment information within it
         as the current membership enrollment snapshot for a trading partner
         */
        
        let path = "/enrollment/snapshot"
        let method = "POST"
        let params = ["trading_partner_id": tradingPartnerId]
        let file = FileData(path: x12FilePath, contentType: "application/EDI-X12")
        
        return request(path: path, method: method, params: params, files: [file])
    }
    
    func enrollmentSnapshots(snapshotId: String? = nil, snapshotsRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
         List enrollment snapshots that are stored for the client application
         */
        
        let path = "/enrollment/snapshot/\(snapshotId ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: snapshotsRequest)
    }
    
    func enrollmentSnapshotData(snapshotId: String) -> Dictionary<String, Any> {
        /*
         List enrollment request objects that make up the specified enrollment snapshot
         */
        
        let path = "/enrollment/snapshot/\(snapshotId)/data"
        let method = "GET"
        
        return request(path: path, method: method)
    }
    
    func icdConvert(code: String) -> Dictionary<String, Any> {
        /*
         Locate the appropriate diagnosis mapping for the specified ICD-9 code
         */
        
        let path = "/icd/convert/\(code)"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func insurancePrices(cptCode: String, zipCode: String) -> Dictionary<String, Any> {
        /*
            Fetch insurance price information
        */

        let path = "/prices/insurance"
        let method = "GET"
        let insurancePricesRequest = ["cpt_code": cptCode, "zip_code" : zipCode]
        
        return request(path: path, method: method, params: insurancePricesRequest)
    }
    
    func mpc(code: String? = nil, name: String? = nil, description: String? = nil) -> Dictionary<String, Any> {
        /*
         Access clinical and consumer friendly information related to medical procedures
         */
        
        let path = "/mpc/\(code ?? "")"
        let method = "GET"
        var mpcRequest: [String: String] = [:]
        if let name = name { mpcRequest["name"] = name }
        if let description = description { mpcRequest["description"] = description }
        
        return request(path: path, method: method, params: mpcRequest)
    }
    
    func oopLoadPrice(oopLoadPriceRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Load pricing data to OOP endpoint
        */
        let path = "/oop/insurance-load-price"
        let method = "POST"
        
        return request(path: path, method: method, params: oopLoadPriceRequest)
    }
    
    func oopEstimate(oopEstimateRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Fetch OOP estimate
        */
        let path = "/oop/insurance-estimate"
        let method = "POST"
        
        return request(path: path, method: method, params: oopEstimateRequest)
    }

    func payers(payersRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Fetch payer information for supported trading partners
        */

        let path = "/payers/"
        let method = "GET"
        
        return request(path: path, method: method, params: payersRequest)
    }

    func plans(plansRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Fetch insurance plans information
        */

        let path = "/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: plansRequest)
    }

    func providers(npi: String? = nil, providersRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Search health care providers in the PokitDok directory
        */

        let path = "/providers/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: providersRequest)
    }

    func tradingPartners(tradingPartnerId: String? = nil) -> Dictionary<String, Any> {
        /*
            Search trading partners in the PokitDok Platform
        */

        let path = "/tradingpartners/\(tradingPartnerId ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func referrals(referralRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Submit a referral request
        */

        let path = "/referrals/"
        let method = "POST"
        
        return request(path: path, method: method, params: referralRequest)
    }

    func schedulers(schedulerUuid: String? = nil) -> Dictionary<String, Any> {
        /*
            Get information about supported scheduling systems or fetch data about a specific scheduling system
        */

        let path = "/schedule/schedulers/\(schedulerUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func appointmentTypes(appointmentTypeUuid: String? = nil) -> Dictionary<String, Any> {
        /*
            Get information about appointment types or fetch data about a specific appointment type
        */

        let path = "/schedule/appointmenttypes/\(appointmentTypeUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func scheduleSlots(slotsRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Submit an open slot for a provider's schedule
        */

        let path = "/schedule/slots/"
        let method = "POST"
        
        return request(path: path, method: method, params: slotsRequest)
    }

    func appointments(appointmentUuid: String? = nil, appointmentsRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Query for open appointment slots or retrieve information for a specific appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: appointmentsRequest)
    }

    func bookAppointment(appointmentUuid: String, appointmentRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Book an appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointmentRequest)
    }

    func updateAppointment(appointmentUuid: String, appointmentRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Update an appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: appointmentRequest)
    }

    func cancelAppointment(appointmentUuid: String) -> Dictionary<String, Any> {
        /*
            Cancel an appointment
        */

        let path = "/schedule/appointments/\(appointmentUuid)"
        let method = "DELETE"
        
        return request(path: path, method: method)
    }

    func createIdentity(identityRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Creates an identity resource
        */

        let path = "/identity/"
        let method = "POST"
        
        return request(path: path, method: method, params: identityRequest)
    }

    func updateIdentity(identityUuid: String, identityRequest: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Updates an existing identity resource.
        */

        let path = "/identity/\(identityUuid)"
        let method = "PUT"
        
        return request(path: path, method: method, params: identityRequest)
    }

    func identity(identityUuid: String? = nil, identityRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Queries for an existing identity resource by uuid or for multiple resources using parameters.
        */

        let path = "/identity/\(identityUuid ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: identityRequest)
    }

    func identityHistory(identityUuid: String, historicalVersion: String? = nil) -> Dictionary<String, Any> {
        /*
            Queries for an identity record's history.
        */

        let path = "identity/\(identityUuid)/history/\(historicalVersion ?? "")"
        let method = "GET"
        
        return request(path: path, method: method)
    }

    func identityMatch(identityMatchData: Dictionary<String, Any>) -> Dictionary<String, Any> {
        /*
            Creates an identity match job.
        */

        let path = "/identity/match"
        let method = "POST"
        
        return request(path: path, method: method, params: identityMatchData)
    }

    func pharmacyPlans(pharmacyPlansRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Search drug plan information by trading partner and various plan identifiers
        */

        let path = "/pharmacy/plans"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacyPlansRequest)
    }

    func pharmacyFormulary(pharmacyFormularyRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Search drug plan formulary information to determine if a drug is covered by the specified drug plan.
        */

        let path = "/pharmacy/formulary"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacyFormularyRequest)
    }

    func pharmacyNetwork(npi: String? = nil, pharmacyNetworkRequest: Dictionary<String, Any>? = nil) -> Dictionary<String, Any> {
        /*
            Search for in-network pharmacies
        */

        let path = "/pharmacy/network/\(npi ?? "")"
        let method = "GET"
        
        return request(path: path, method: method, params: pharmacyNetworkRequest)
    }

}
