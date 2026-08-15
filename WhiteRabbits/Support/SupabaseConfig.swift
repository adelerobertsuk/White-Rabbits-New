//
//  SupabaseConfig.swift
//  WhiteRabbits
//
//  One shared Supabase client for the whole app. Only Circle data
//  (name, monthly intention, charm, sparks) ever touches this. The
//  publishable key below is safe to ship in the app, it's designed
//  to be public-facing, the same way it would appear in a website's
//  client-side code.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://rrrjojbxjektdhrkahvh.supabase.co")!
    static let publishableKey = "sb_publishable_yHobfTk-tHz7umWUrDcfuw_X2aql15E"
    static let intentionPhotosBucket = "intention-photos"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.projectURL,
    supabaseKey: SupabaseConfig.publishableKey
)
