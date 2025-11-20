//
//  ContentView.swift
//  CatMood
//

import SwiftUI

//зберігає інфу про настрій
struct MoodNote: Identifiable, Codable, Equatable {
    let id: UUID
    var moodIndex: Int?
    var text: String
    var date: Date

    init(id: UUID = UUID(), moodIndex: Int? = nil, text: String, date: Date = Date()) {
        self.id = id
        self.moodIndex = moodIndex
        self.text = text
        self.date = date
    }
}

//картінкі котів та цитати
enum MoodAssets {
    static let cats = ["sad", "angry", "calm", "happy", "tired"]
    static let catsSmall = ["sad_cat", "angry_cat", "calm_cat", "happy_cat", "tired_cat"]
    static let catsPressed = ["yellow_sad_cat", "yellow_angry_cat", "yellow_calm_cat", "yellow_happy_cat", "yellow_tired_cat"]
    static let quotes = [
        "Варто тільки повірити, що ви можете — і ви вже на півдорозі до цілі",
        "Все приходить до того, хто вміє чекати.",
        "Кожен день — нова можливість.",
        "Ти сильніший, ніж думаєш.",
        "Усміхнись — і світ усміхнеться тобі.",
        "Сьогодні — найкращий день, щоб почати щось нове.",
        "Маленькі кроки ведуть до великих змін.",
        "Іноді найкраще, що ти можеш зробити — це просто продовжувати.",
        "Навіть маленький промінь світла розганяє темряву.",
        "Ти заслуговуєш на спокій, любов і турботу.",
        "Погані дні минають — а твоя сила залишається.",
        "Дбай про себе так само, як піклуєшся про інших.",
        "Ніхто не ідеальний, і це нормально.",
        "Те, що сьогодні здається важким, завтра стане твоєю перемогою.",
        "Навіть найменше кошеня іноді реве, як лев — і ти теж можеш.",
        "Коти не здаються — вони просто дрімають і повертаються сильнішими.",
        "Ідеальний момент не завжди приходить — зате приходить енергія діяти.",
        "Крок за кроком, день за днем — і ти вже зовсім інша людина.",
        "Не забувай муркотіти про свої перемоги — навіть маленькі.",
        "Іноді найкращий план — зупинитися, глибоко вдихнути і продовжити.",
        "Твоя історія не закінчується тут — попереду ще багато світла.",
        "Коли життя шипить — нагадуй собі, що ти тигр, а не миша.",
        "Ти не повинен бути ідеальним, щоб бути цінним.",
        "М'яко до себе — ти робиш усе, що можеш, і цього достатньо.",
        "Темні дні не назавжди — свято світла вже на підході.",
        "Зупинись, потягнись, видихни — інколи це і є шлях вперед.",
        "Внутрішній спокій — це теж успіх.",
        "Якщо в тебе сьогодні мало сил — добре. Відпочинок теж частина шляху."
    ]
}

//завантаження нотаток з пам'яті
extension UserDefaults {
    private static let notesKey = "CatMood_notes"
    
    func loadNotes() -> [MoodNote] {
        guard let data = data(forKey: Self.notesKey),
              let notes = try? JSONDecoder().decode([MoodNote].self, from: data) else {
            return []
        }
        return notes.sorted { $0.date > $1.date }
    }

    func saveNotes(_ notes: [MoodNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            set(data, forKey: Self.notesKey)
        }
    }
}

// порівняння дат
extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

//головний екран
struct ContentView: View {
    @State private var selectedMood: Int? = nil
    @State private var inputText = ""
    @State private var notes: [MoodNote] = []
    @State private var editingNote: MoodNote? = nil
    @State private var isEditSheetPresented = false
    @FocusState private var isInputFocused: Bool

    private var todayNote: MoodNote? {
        notes.first { $0.date.isSameDay(as: Date()) }
    }

    private var quoteOfTheDay: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return MoodAssets.quotes[(dayOfYear - 1) % MoodAssets.quotes.count]
    }

    private var currentBigCat: String {
        selectedMood.map { MoodAssets.cats[$0] } ?? "defaultCat"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Який настрій у тебе сьогодні?")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 40)

                Image(currentBigCat)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .shadow(radius: 10)

                MoodSelector(selectedMood: $selectedMood)

                if todayNote == nil {
                    InputField(text: $inputText, isFocused: $isInputFocused, onSave: saveNote)
                }

                SectionHeader(icon: "heart.text.square.fill", text: "Твій настрій сьогодні")

                if let note = todayNote {
                    NoteCard(
                        note: note,
                        moodImage: moodImage(for: note.moodIndex),
                        onEdit: { editNote(note) },
                        onDelete: { deleteNote(note) }
                    )
                    .padding(.horizontal)
                }

                QuoteSection(quote: quoteOfTheDay)

                Spacer()

                BottomNavigation()
            }
        }
        .onAppear {
            notes = UserDefaults.standard.loadNotes()
        }
        .sheet(isPresented: $isEditSheetPresented) {
            if let note = editingNote {
                EditNoteSheet(note: note) { updatedNote in
                    if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                        notes[index] = updatedNote
                        UserDefaults.standard.saveNotes(notes)
                    }
                    isEditSheetPresented = false
                }
            }
        }
    }

    private func moodImage(for index: Int?) -> String {
        index.map { MoodAssets.cats[$0] } ?? "defaultCat"
    }

    private func saveNote() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        notes.insert(MoodNote(moodIndex: selectedMood, text: text), at: 0)
        UserDefaults.standard.saveNotes(notes)
        inputText = ""
        isInputFocused = false
    }

    private func editNote(_ note: MoodNote) {
        editingNote = note
        isEditSheetPresented = true
    }

    private func deleteNote(_ note: MoodNote) {
        notes.removeAll { $0.id == note.id }
        UserDefaults.standard.saveNotes(notes)
    }
}

//відображення котів для вибору
struct MoodSelector: View {
    @Binding var selectedMood: Int?

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<MoodAssets.cats.count, id: \.self) { index in
                let isSelected = selectedMood == index
                Image(isSelected ? MoodAssets.catsPressed[index] : MoodAssets.catsSmall[index])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55, height: 55)
                    .scaleEffect(isSelected ? 1.25 : 1.0)
                    .shadow(color: isSelected ? .yellow.opacity(0.5) : .clear, radius: 8)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedMood = index
                        }
                    }
            }
        }
    }
}

//поле для вводу інфи в замітку
struct InputField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSave: () -> Void

    var body: some View {
        HStack {
            TextField("Напишіть про свій настрій...", text: $text)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .focused(isFocused)
                .submitLabel(.done)
                .onSubmit(onSave)

            Button {
                isFocused.wrappedValue = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.white)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}

//підзаголовок з жовтою іконкою
struct SectionHeader: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.yellow)
            Text(text)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
    }
}

//блок з цитатою
struct QuoteSection: View {
    let quote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Цитата дня:")
                .foregroundColor(.gray)
            Text(quote)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
}

//нижнє меню
struct BottomNavigation: View {
    var body: some View {
        HStack(spacing: 60) {
            Image(systemName: "calendar")
            Image(systemName: "house.fill")
            Image(systemName: "pawprint.fill")
        }
        .foregroundColor(.white)
        .font(.title2)
        .padding(.bottom, 20)
    }
}

//картка з нотаткою про настрій та можливість редагувати/видалити
struct NoteCard: View {
    let note: MoodNote
    let moodImage: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(moodImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            Text(note.text)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(16)
    }
}

//редагування нотатки
struct EditNoteSheet: View {
    @State var note: MoodNote
    let onSave: (MoodNote) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Редагувати запис")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    MoodEditSelector(selectedMood: $note.moodIndex)
                    
                    TextEditSection(text: $note.text, isFocused: $isFocused)
                    
                    Spacer()
                    
                    ActionButtons(
                        onCancel: { dismiss() },
                        onSave: {
                            note.date = Date()
                            onSave(note)
                            dismiss()
                        }
                    )
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

//зміна настрою в режимі редагування
struct MoodEditSelector: View {
    @Binding var selectedMood: Int?

    var body: some View {
        VStack(spacing: 12) {
            Text("Настрій:")
                .foregroundColor(.gray)
                .font(.subheadline)
            
            HStack(spacing: 16) {
                ForEach(0..<MoodAssets.catsSmall.count, id: \.self) { index in
                    let isSelected = selectedMood == index
                    
                    Image(isSelected ? MoodAssets.catsPressed[index] : MoodAssets.catsSmall[index])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .shadow(color: isSelected ? .yellow.opacity(0.5) : .clear, radius: 6)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedMood = index
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

//зміна тексту в режимі редагування
struct TextEditSection: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Опис:")
                .foregroundColor(.gray)
                .font(.subheadline)
            
            ZStack {
                Color.white.opacity(0.1)
                    .cornerRadius(12)
                
                TextEditor(text: $text)
                    .padding(10)
                    .foregroundColor(.white)
                    .focused(isFocused)
                    .scrollContentBackground(.hidden)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Готово") {
                                isFocused.wrappedValue = false
                            }
                        }
                    }
            }
            .frame(minHeight: 150)
        }
        .padding(.horizontal)
    }
}

//кнопки скасувати та зберегти
struct ActionButtons: View {
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button("Скасувати", action: onCancel)
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            Button("Зберегти", action: onSave)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}
