//
//  ScheduleMeetingTimeView.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/27/25.
//

struct ScheduleMeetingTimeView: View {
    @State private var newDate = Date() // Default to the current date and time
    @Binding var isPresented: Bool // To dismiss the view after selection
    @Binding var rescheduledDate: Date // The updated date for the meeting
    let meetingId: String
    
    
    var body: some View {
        
        VStack {
            Text("Select New Date and Time")
                .font(.title)
                .padding()

            DatePicker(
                "Select Date and Time",
                selection: $newDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(WheelDatePickerStyle())
            .padding()

            Button("Confirm Reschedule") {
                rescheduledDate = newDate // Update the rescheduled date
                isPresented = false // Dismiss the view
                // You can add your backend logic to save the updated date for the meeting
                print("Meeting \(meetingId) rescheduled to: \(newDate)")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Cancel") {
                isPresented = false // Dismiss the view without changes
            }
            .padding()
        }
        .navigationTitle("Reschedule Meeting")
        .padding()
    }

}

struct ScheduleMeetingTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleMeetingTimeView(isPresented: .constant(true), rescheduledDate: .constant(Date()), meetingId: "12345")
    }
}
