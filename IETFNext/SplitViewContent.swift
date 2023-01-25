//
//  SplitViewContent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/18/23.
//

import SwiftUI

struct SplitViewContent: View {
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var selectedLocation: Location?
    @Binding var selectedDownload: Download?
    @Binding var selectedRFC: RFC?
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var groupFilterMode: GroupFilterMode
    @Binding var rfcFilterMode: RFCFilterMode
    var listMode: SidebarOption
    @Binding var shortTitle: String?
    @Binding var longTitle: String?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var sessionFormatter: DateFormatter? = nil
    let SB_MIN = 270.0         // sidebar minimum size
    let SB_IDEAL = 320.0       // sidebar ideal size
    let SB_MAX = 370.0         // sidebar maximum size

    var body: some View {
        VStack {
            switch(listMode) {
            case .schedule:
                SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup, sessionFilterMode: $sessionFilterMode, sessionFormatter: $sessionFormatter, html:$html, columnVisibility:$columnVisibility)
                    .keyboardShortcut("s")
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            case .groups:
                GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup, groupFilterMode: $groupFilterMode, html:$html, columnVisibility:$columnVisibility)
                    .keyboardShortcut("g")
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            case .locations:
                LocationListView(selectedMeeting: $selectedMeeting, selectedLocation: $selectedLocation, columnVisibility: $columnVisibility)
                    .keyboardShortcut("l")
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            case .rfc:
                RFCListView(selectedRFC:$selectedRFC, selectedDownload:$selectedDownload, rfcFilterMode: $rfcFilterMode, listMode: listMode, shortTitle: $shortTitle, longTitle: $longTitle, html:$html, localFileURL:$localFileURL, columnVisibility: $columnVisibility)
                    .keyboardShortcut("r")
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            case .bcp:
                RFCListView(selectedRFC:$selectedRFC, selectedDownload:$selectedDownload, rfcFilterMode: $rfcFilterMode, listMode: listMode, shortTitle: $shortTitle, longTitle: $longTitle, html:$html, localFileURL:$localFileURL, columnVisibility: $columnVisibility)
                    .keyboardShortcut("b")
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            case .fyi, .std:
                RFCListView(selectedRFC:$selectedRFC, selectedDownload:$selectedDownload, rfcFilterMode: $rfcFilterMode, listMode: listMode, shortTitle: $shortTitle, longTitle: $longTitle, html:$html, localFileURL:$localFileURL, columnVisibility: $columnVisibility)
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            case .download:
                DownloadListView(selectedDownload:$selectedDownload, html:$html, localFileURL:$localFileURL, columnVisibility:$columnVisibility)
                    .keyboardShortcut("d")
                    .navigationSplitViewColumnWidth(min: SB_MIN, ideal: SB_IDEAL, max: SB_MAX)
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: Locale.current.identifier)
            formatter.dateFormat = "yyyy-MM-dd EEEE"
            formatter.calendar = Calendar(identifier: .iso8601)
            if let meeting = newValue {
                formatter.timeZone = TimeZone(identifier: meeting.time_zone!)
            } else {
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
            }
            sessionFormatter = formatter
        }
    }
}
