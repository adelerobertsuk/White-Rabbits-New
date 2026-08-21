//
//  StudioContact.swift
//  WhiteRabbits
//
//  Public studio links used from Preferences.
//

import Foundation

enum StudioContact {
    static let supportEmail = "hello@akastudio.uk"
    static let studioURL = URL(string: "https://akastudio.uk")!
    static let supportURL = URL(string: "https://akastudio.uk/support")!
    static let privacyURL = URL(string: "https://akastudio.uk/privacy")!

    static var supportMailtoURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "White Rabbits")
        ]
        return components.url ?? URL(string: "mailto:\(supportEmail)")!
    }
}
