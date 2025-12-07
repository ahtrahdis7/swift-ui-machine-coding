//
//  API_KeyService.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 07/12/25.
//

protocol API_KeyServiceProtocol {
    func getAPIKey() throws -> String
    func saveAPIKey(_ key: String) throws
    func hasAPIKey() -> Bool
}

//class API_KeyService: API_KeyServiceProtocol {
//    func getAPIKey() throws -> String {
//        //
//    }
//    
//    func saveAPIKey(_ key: String) throws {
//        //
//    }
//    
//    func hasAPIKey() -> Bool {
//        //
//    }
//}
