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
    @Binding var sessionFormatter: DateFormatter?
    @Binding var timerangeFormatter: DateFormatter?
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var groupFilterMode: GroupFilterMode
    @Binding var rfcFilterMode: RFCFilterMode
    var listMode: SidebarOption
    @Binding var locationDetailMode: LocationDetailMode
    @Binding var shortTitle: String?
    @Binding var longTitle: String?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility


    var body: some View {
        VStack {
            switch(listMode) {
            case .schedule:
                SessionListFilteredView(
                    selectedMeeting: $selectedMeeting,
                    selectedGroup: $selectedGroup,
                    sessionFilterMode: $sessionFilterMode,
                    sessionFormatter: $sessionFormatter,
                    timerangeFormatter: $timerangeFormatter,
                    html:$html,
                    columnVisibility:$columnVisibility
                )
                    .keyboardShortcut("s")
            case .groups:
                GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup, groupFilterMode: $groupFilterMode, html:$html, columnVisibility:$columnVisibility)
                    .keyboardShortcut("g")
            case .locations:
                LocationListView(selectedMeeting: $selectedMeeting, selectedLocation: $selectedLocation, locationDetailMode: $locationDetailMode, columnVisibility: $columnVisibility)
                    .keyboardShortcut("l")
            case .rfc:
                RFCListView(selectedRFC:$selectedRFC, selectedDownload:$selectedDownload, rfcFilterMode: $rfcFilterMode, listMode: listMode, shortTitle: $shortTitle, longTitle: $longTitle, html:$html, localFileURL:$localFileURL, columnVisibility: $columnVisibility)
                    .keyboardShortcut("r")
            case .bcp:
                RFCListView(selectedRFC:$selectedRFC, selectedDownload:$selectedDownload, rfcFilterMode: $rfcFilterMode, listMode: listMode, shortTitle: $shortTitle, longTitle: $longTitle, html:$html, localFileURL:$localFileURL, columnVisibility: $columnVisibility)
                    .keyboardShortcut("b")
            case .fyi, .std:
                RFCListView(selectedRFC:$selectedRFC, selectedDownload:$selectedDownload, rfcFilterMode: $rfcFilterMode, listMode: listMode, shortTitle: $shortTitle, longTitle: $longTitle, html:$html, localFileURL:$localFileURL, columnVisibility: $columnVisibility)
            case .download:
                DownloadListView(selectedDownload:$selectedDownload, html:$html, localFileURL:$localFileURL, columnVisibility:$columnVisibility)
                    .keyboardShortcut("d")
            }
        }
    }
}
