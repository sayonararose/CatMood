import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \MoodNote.date, order: .reverse) private var notes: [MoodNote]
    @Environment(\.modelContext) private var modelContext

    // Календарна логіка
    @State private var currentMonth: Date = Date()
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7) // 7 днів у тижні

    // Стан для інтерактивності
    @State private var selectedNote: MoodNote? = nil
    @State private var noteToEdit: MoodNote? = nil
    @State private var noteToDelete: MoodNote? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Історія Настроїв")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                
                // Заголовок місяця
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow)
                    }
                    
                    Text(monthYearString(from: currentMonth))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 150)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
                
                // Дні тижня
                HStack {
                    ForEach(["Нд", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Сітка календаря
                // Ми беремо дні разом з їх індексами (enumerated),
                // щоб кожен елемент мав унікальний ID (offset).
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(Array(daysInMonth().enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            DayCell(date: date, note: noteForDate(date)) {
                                if let note = noteForDate(date) {
                                    selectedNote = note
                                }
                            }
                        } else {
                            Text("") // Пуста клітинка
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Легенда або список
                if notes.isEmpty {
                    Text("Поки немає записів")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
        // Лист деталей нотатки
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(
                note: note,
                onEdit: {
                    selectedNote = nil
                    noteToEdit = note
                },
                onDelete: {
                    selectedNote = nil
                    noteToDelete = note
                }
            )
        }
        // Вікно редагування
        .sheet(item: $noteToEdit) { note in
            EditNoteSheet(note: note)
                .presentationBackground(.black)
        }
        // Підтвердження видалення
        .alert("Видалити запис?", isPresented: Binding(
            get: { noteToDelete != nil },
            set: { if !$0 { noteToDelete = nil } }
        )) {
            Button("Скасувати", role: .cancel) {
                noteToDelete = nil
            }
            Button("Видалити", role: .destructive) {
                if let note = noteToDelete {
                    modelContext.delete(note)
                    noteToDelete = nil
                }
            }
        } message: {
            Text("Ви впевнені, що хочете видалити цей запис?")
        }
    }
    
    private func noteForDate(_ date: Date) -> MoodNote? {
        notes.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA") // Українська локалізація
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        let firstDayWeekday = calendar.component(.weekday, from: monthInterval.start)
        
        // Swift Calendar: Sunday = 1. Потрібно вирахувати зсув.
        let offset = firstDayWeekday - 1
        
        // Створюємо масив, де на початку йдуть nil (пусті місця)
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let note: MoodNote?
    let onTap: () -> Void

    var body: some View {
        VStack {
            if let note = note, let index = note.moodIndex {
                // Якщо є запис - показуємо котика
                Image(MoodAssets.catsSmall[index])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        HapticManager.shared.light()
                        onTap()
                    }
            } else {
                // Якщо немає - просто число
                Text("\(Calendar.current.component(.day, from: date))")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

// КОМПОНЕНТ: Деталі нотатки
struct NoteDetailSheet: View {
    let note: MoodNote
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Іконка настрою
                    if let index = note.moodIndex {
                        Image(MoodAssets.catsSmall[index])
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding(.top, 20)
                    }

                    // Дата
                    Text(formattedDate(note.date))
                        .font(.headline)
                        .foregroundColor(.yellow)

                    // Текст нотатки
                    ScrollView {
                        if note.text.isEmpty {
                            Text("Опис настрою не заповнений")
                                .foregroundColor(.gray)
                                .italic()
                                .padding()
                        } else {
                            Text(note.text)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .frame(maxHeight: 300)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer()

                    // Кнопки дій
                    HStack(spacing: 16) {
                        Button {
                            onEdit()
                            dismiss()
                        } label: {
                            Label("Редагувати", systemImage: "pencil")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.yellow)
                                .cornerRadius(12)
                        }

                        Button {
                            HapticManager.shared.warning()
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Видалити", systemImage: "trash")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрити") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMMM yyyy"
        return "День настрою: \(formatter.string(from: date))"
    }
}

