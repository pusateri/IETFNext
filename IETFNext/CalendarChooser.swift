/*
 Copyright © 2023 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Abstract:
The calendar chooser view controller that allows the user to select a single
    calendar.
*/

#if !os(macOS)
import EventKitUI
import SwiftUI

struct CalendarChooser: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var storeManager: EventStoreManager
    
    /// Keeps track of the calendar the user selected in the calendar chooser view controller.
    @Binding var calendar: EKCalendar?
    
    func makeUIViewController(context: Context) -> UINavigationController {
        // Initializes a calendar chooser that allows the user to select a single calendar from a list of writable calendars only.
        let calendarChooser = EKCalendarChooser(selectionStyle: .single,
                                                displayStyle: .writableCalendarsOnly,
                                                entityType: .event,
                                                eventStore: storeManager.dataStore.eventStore)
        /*
            Set up the selected calendars property. If the user previously selected a calendar from the view controller, update the property with it.
            Otherwise, update selected calendars with an empty set.
        */
        if let calendar = calendar {
            let selectedCalendar: Set<EKCalendar> = [calendar]
            calendarChooser.selectedCalendars = selectedCalendar
        } else {
            calendarChooser.selectedCalendars = []
        }
        calendarChooser.delegate = context.coordinator
        
        // Configure the chooser to display Done and Cancel buttons.
        calendarChooser.showsDoneButton = true
        calendarChooser.showsCancelButton = true
        return UINavigationController(rootViewController: calendarChooser)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, EKCalendarChooserDelegate {
        var parent: CalendarChooser
        
        init(_ controller: CalendarChooser) {
            self.parent = controller
        }
        
        /// The system calls this when the user taps Done in the UI. Save the user's choice.
        func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
            parent.calendar = calendarChooser.selectedCalendars.first
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        /// The system calls this when the user taps Cancel in the UI. Dismiss the calendar chooser.
        func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif
