//
//  Persistence.swift
//  WhiteRabbits
//
//  Everything about saving to this phone only. No servers, no accounts.
//  The journal itself is JSON on disk, and any photos live next to it
//  as small compressed JPEGs.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum Persistence {
    private static let fileName = "white-rabbits-store.json"

    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var storeURL: URL {
        documentsURL.appendingPathComponent(fileName)
    }

    private static var photosURL: URL {
        let url = documentsURL.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func load() -> AppData {
        guard let data = try? Data(contentsOf: storeURL) else { return AppData() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(AppData.self, from: data)) ?? AppData()
    }

    static func save(_ appData: AppData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(appData) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    /// Saves a photo to disk and returns the file name to keep in a model.
    #if canImport(UIKit)
    static func savePhoto(_ image: UIImage) -> String? {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        let url = photosURL.appendingPathComponent(fileName)
        do {
            try jpegData.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }

    static func loadPhoto(_ fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        let url = photosURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    #endif

    static func deletePhoto(_ fileName: String?) {
        guard let fileName else { return }
        let url = photosURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
