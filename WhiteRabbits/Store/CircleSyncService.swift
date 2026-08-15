//
//  CircleSyncService.swift
//  WhiteRabbits
//
//  Everything needed to keep the Circle tab (names, monthly intentions,
//  charms, sparks) in sync across every phone signed into our Supabase
//  project. Journal, habits, and check-ins never come near this file,
//  they stay local-only on each device.
//
//  Identity: tapping "Enter the circle" signs this device in anonymously
//  (no email, no password, no visible login screen), same feel as before,
//  just with a real, stable id behind the scenes.
//

import Foundation
import Supabase

enum CircleSyncError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Enter the circle first to sync with everyone else."
        }
    }
}

enum CircleSyncService {

    // MARK: - Identity

    /// The signed-in Supabase user id, if any. `nil` until "Enter the circle" is tapped.
    static var currentUserID: UUID? {
        supabase.auth.currentUser?.id
    }

    /// Signs this device in anonymously (only once, ever) and saves the display name.
    /// Safe to call again later, e.g. after a name change or app relaunch.
    @discardableResult
    static func joinCircle(displayName: String) async throws -> UUID {
        let userID: UUID
        if let existing = supabase.auth.currentUser?.id {
            userID = existing
        } else {
            let session = try await supabase.auth.signInAnonymously()
            userID = session.user.id
        }
        try await upsertMembership(userID: userID, displayName: displayName)
        return userID
    }

    /// Pushes a new display name for someone already in the circle.
    static func updateDisplayName(_ displayName: String) async throws {
        guard let userID = currentUserID else { return }
        try await upsertMembership(userID: userID, displayName: displayName)
    }

    private struct MemberUpsert: Encodable {
        let user_id: UUID
        let display_name: String
    }

    private static func upsertMembership(userID: UUID, displayName: String) async throws {
        try await supabase
            .from("circle_members")
            .upsert(
                MemberUpsert(user_id: userID, display_name: displayName),
                onConflict: "user_id"
            )
            .execute()
    }

    // MARK: - Members

    struct RemoteMember: Codable, Identifiable, Sendable {
        let user_id: UUID
        var display_name: String
        var id: UUID { user_id }
    }

    /// Every member of the circle, including this device, so Circle can show
    /// real names and cards instead of the old placeholder "Fellows" list.
    static func fetchMembers() async throws -> [RemoteMember] {
        try await supabase
            .from("circle_members")
            .select("user_id, display_name")
            .execute()
            .value
    }

    // MARK: - Intentions

    struct RemoteIntention: Codable, Sendable {
        let user_id: UUID
        var month_key: String
        var text: String
        var charm_id: String?
        var photo_path: String?
    }

    /// This month's intention from every member, so Circle can show everyone's card.
    static func fetchIntentions(monthKey: String) async throws -> [RemoteIntention] {
        try await supabase
            .from("intentions")
            .select("user_id, month_key, text, charm_id, photo_path")
            .eq("month_key", value: monthKey)
            .execute()
            .value
    }

    static func fetchMyIntention(monthKey: String) async throws -> RemoteIntention? {
        guard let userID = currentUserID else { return nil }
        let rows: [RemoteIntention] = try await supabase
            .from("intentions")
            .select("user_id, month_key, text, charm_id, photo_path")
            .eq("user_id", value: userID)
            .eq("month_key", value: monthKey)
            .execute()
            .value
        return rows.first
    }

    private struct IntentionUpsert: Encodable {
        let user_id: UUID
        let month_key: String
        let text: String
        let charm_id: String?
        let photo_path: String?
    }

    /// Saves (or updates) my own intention for this month. Pass `photoData` only
    /// when the photo actually changed; passing `nil` keeps whatever was there before.
    static func setIntention(
        monthKey: String,
        text: String,
        charmID: String?,
        photoData: Data?
    ) async throws {
        guard let userID = currentUserID else {
            throw CircleSyncError.notSignedIn
        }

        let photoPath: String?
        if let photoData {
            photoPath = try await uploadIntentionPhoto(userID: userID, monthKey: monthKey, data: photoData)
        } else {
            photoPath = try await fetchMyIntention(monthKey: monthKey)?.photo_path
        }

        try await supabase
            .from("intentions")
            .upsert(
                IntentionUpsert(
                    user_id: userID,
                    month_key: monthKey,
                    text: text,
                    charm_id: charmID,
                    photo_path: photoPath
                ),
                onConflict: "user_id,month_key"
            )
            .execute()
    }

    private static func uploadIntentionPhoto(userID: UUID, monthKey: String, data: Data) async throws -> String {
        let path = "\(userID.uuidString)/\(monthKey).jpg"
        _ = try await supabase.storage
            .from(SupabaseConfig.intentionPhotosBucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )
        return path
    }

    /// The public, ready-to-display URL for a stored intention photo path.
    static func photoURL(for path: String) -> URL? {
        try? supabase.storage
            .from(SupabaseConfig.intentionPhotosBucket)
            .getPublicURL(path: path)
    }

    // MARK: - Sparks

    private struct SparkToRow: Decodable {
        let to_user_id: UUID
    }

    /// Every spark I've sent this month, so a "Send a Spark" button can flip
    /// to "Sparked" for people I've already reached out to.
    static func fetchSparksSentByMe(monthKey: String) async throws -> Set<UUID> {
        guard let userID = currentUserID else { return [] }
        let rows: [SparkToRow] = try await supabase
            .from("sparks")
            .select("to_user_id")
            .eq("from_user_id", value: userID)
            .eq("month_key", value: monthKey)
            .execute()
            .value
        return Set(rows.map(\.to_user_id))
    }

    private struct SparkInsert: Encodable {
        let from_user_id: UUID
        let to_user_id: UUID
        let month_key: String
    }

    static func sendSpark(to recipientID: UUID, monthKey: String) async throws {
        guard let userID = currentUserID else {
            throw CircleSyncError.notSignedIn
        }
        try await supabase
            .from("sparks")
            .upsert(
                SparkInsert(from_user_id: userID, to_user_id: recipientID, month_key: monthKey),
                onConflict: "from_user_id,to_user_id,month_key",
                ignoreDuplicates: true
            )
            .execute()
    }
}
