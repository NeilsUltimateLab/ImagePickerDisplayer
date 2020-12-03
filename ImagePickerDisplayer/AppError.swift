//
//  AppError.swift
//  ImagePickerDisplayer
//
//  Created by Neil on 03/12/20.
//

import Foundation

enum AppError: Equatable, Error {
    case authentication(String)
    case message(String)
    case canNotParse
    case somethingWentWrong
}

extension AppError {
    var isAuthentication: Bool {
        switch self {
        case .authentication:
            return true
        default:
            return false
        }
    }
    
    var title: String? {
        switch self {
        case .authentication:
            return "Authentication Required"
        case .message:
            return nil
        case .canNotParse:
            return "Oops"
        case .somethingWentWrong:
            return "Oops"
        }
    }
    
    var message: String? {
        switch self {
        case .authentication(let message):
            return message
        case .message(let message):
            return message
        case .canNotParse:
            return "Something went wrong from our side."
        case .somethingWentWrong:
            return "Something went wrong from our side."
        }
    }
}
