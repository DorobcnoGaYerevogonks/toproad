import SwiftUI

struct DailyNotesView: View {
    @Binding var trip: Trip

    private var days: [Date] {
        guard trip.endDate >= trip.startDate else { return [] }
        var arr: [Date] = []
        var d = Calendar.current.startOfDay(for: trip.startDate)
        let end = Calendar.current.startOfDay(for: trip.endDate)
        while d <= end {
            arr.append(d)
            d = Calendar.current.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return arr
    }

    var body: some View {
        List {
            ForEach(days, id: \.self) { day in
                let bindingText = Binding<String>(
                    get: { existingText(for: day) },
                    set: { newValue in
                        updateNote(for: day, text: newValue)
                    }
                )
                Section(header: Text(dateString(day))) {
                    TextEditor(text: bindingText)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if bindingText.wrappedValue.isEmpty {
                                Text("daily_note_placeholder")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                }
            }
        }
        .navigationTitle(Text("daily_notes_title"))
    }

    private func existingText(for date: Date) -> String {
        let key = Calendar.current.startOfDay(for: date)
        return trip.dailyNotes.first(where: { Calendar.current.isDate($0.date, inSameDayAs: key) })?.text ?? ""
    }

    private func updateNote(for date: Date, text: String) {
        let key = Calendar.current.startOfDay(for: date)
        if let idx = trip.dailyNotes.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: key) }) {
            trip.dailyNotes[idx].text = text
        } else if !text.isEmpty {
            trip.dailyNotes.append(DailyNote(date: key, text: text))
        }
        // чистим пустые
        trip.dailyNotes.removeAll { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .full
        return df.string(from: date)
    }
}
