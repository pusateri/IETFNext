//
//  MeetingListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/28/22.
//

import SwiftUI
import CoreData


struct Meetings: Decodable {
    let meta: Meta
    let objects: [JSONMeeting]
}

struct JSONMeeting: Decodable {
    let acknowledgements: String
    let agenda: String
    let agenda_info_note: String
    let agenda_warning_note: String
    let attendees: Int32?
    let break_area: String
    let city: String
    let country: String
    let date: String
    let days: Int32
    let id: Int32
    let idsubmit_cutoff_day_offset_00: Int32
    let idsubmit_cutoff_day_offset_01: Int32
    let idsubmit_cutoff_time_utc: String
    let idsubmit_cutoff_warning_days: String
    let number: String
    let proceedings_final: Bool
    let reg_area: String
    let resource_uri: String
    let schedule: String
    let session_request_lock_message: String
    let show_important_dates: Bool
    let submission_correction_day_offset: Int32
    let submission_cutoff_day_offset: Int32
    let submission_start_day_offset: Int32
    let time_zone: String
    let type: String
    let updated: String
    let venue_addr: String
    let venue_name: String
}

struct MeetingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMeeting: Meeting?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meeting.date, ascending: false)],
        animation: .default)
    private var meetings: FetchedResults<Meeting>

    var body: some View {
        NavigationView {
            List(meetings, id: \.self, selection: $selectedMeeting) { mtg in
                MeetingListRowView(meeting: mtg)
                    .listRowSeparator(.visible)
            }
            .frame(minWidth: 600, idealWidth: 600, minHeight: 600, idealHeight: 600)
            .listRowInsets(EdgeInsets())
            .navigationTitle("IETF \(selectedMeeting?.number! ?? "Select Meeting")")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedMeeting) { newValue in
                if let meeting = newValue {
                    UserDefaults.standard.set(meeting.number!, forKey:"MeetingNumber")
                    Task {
                        await loadData(context: viewContext, meeting: meeting)
                    }
                }
                dismiss()
            }
            .task {
                await loadMeetings(context:viewContext, limit:0, offset:0)
            }
        }
#if os(macOS)
        .frame(width: 600, height: 600)
#endif
    }
}

private func buildRFC3339DateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}

private func buildRFC3339FractionalDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.ssss"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}

private func buildDateFormatter(time_zone: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(identifier: time_zone)

    return formatter
}

private func loadMeetings(context: NSManagedObjectContext, limit: Int32, offset: Int32) async {
    let url: URL
    if limit == 0 {
        guard let all_url = URL(string: "https://datatracker.ietf.org/api/v1/meeting/meeting/?type=ietf") else {
            print("Invalid URL")
            return
        }
        url = all_url
    } else {
        guard let limit_url = URL(string: "https://datatracker.ietf.org/api/v1/meeting/meeting/?type=ietf&limit=\(limit)&offset=\(offset)") else {
            print("Invalid URL")
            return
        }
        url = limit_url
    }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            //decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
            let json_meetings = try decoder.decode(Meetings.self, from: data)

            context.performAndWait {
                for obj in json_meetings.objects {
                    updateMeeting(context:context, meeting:obj)
                }
            }
        } catch DecodingError.dataCorrupted(let context) {
            print(context)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
    } catch {
        print("Unexpected Meeting format")
    }
}

private func updateMeeting(context: NSManagedObjectContext, meeting: JSONMeeting) {
    let mtg: Meeting!

    let fetchMeeting: NSFetchRequest<Meeting> = Meeting.fetchRequest()
    fetchMeeting.predicate = NSPredicate(format: "number = %@", meeting.number)

    let results = try? context.fetch(fetchMeeting)

    if results?.count == 0 {
        // here you are inserting
        mtg = Meeting(context: context)

    } else {
        // here you are updating
        mtg = results?.first
    }

    let dateFormatter = buildDateFormatter(time_zone: meeting.time_zone)
    let RFC3339DateFormatter = buildRFC3339DateFormatter()
    let RFC3339FractionalDateFormatter = buildRFC3339FractionalDateFormatter()
    mtg.acknowledgements = meeting.acknowledgements
    mtg.city = meeting.city
    mtg.country = meeting.country
    mtg.number = meeting.number
    mtg.date = meeting.date
    mtg.start = dateFormatter.date(from: meeting.date)
    mtg.time_zone = meeting.time_zone
    mtg.updated_at = RFC3339DateFormatter.date(from: meeting.updated)
    if mtg.updated_at == nil {
        mtg.updated_at = RFC3339FractionalDateFormatter.date(from: meeting.updated)
    }
    mtg.venue_addr = meeting.venue_addr
    mtg.venue_name = meeting.venue_name

    do {
        try context.save()
    }
    catch {
        print("Unable to save Meeting \(meeting.number)")
    }
}

public func selectMeeting(context: NSManagedObjectContext, number: String?) -> Meeting? {
    if let number = number {
        let fetchMeeting: NSFetchRequest<Meeting> = Meeting.fetchRequest()
        fetchMeeting.predicate = NSPredicate(format: "number = %@", number)

        let results = try? context.fetch(fetchMeeting)

        if let meetings = results, meetings.count > 0 {
            return meetings.first
        }
    }
    return nil
}
