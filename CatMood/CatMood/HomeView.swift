//
//  HomeView.swift
//  CatMood
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // Підключаємо базу даних
    @Environment(\.modelContext) private var modelContext
    // Завантажуємо записи
    @Query(sort: \MoodNote.date, order: .reverse) private var notes: [MoodNote]

    @Binding var selectedTab: Int // Додаємо зв'язок з навігацією
    @State private var selectedMood: Int? = nil
    @State private var inputText = ""
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
        selectedMood.map { MoodAssets.cats[$0] } ?? "calm"
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
                } else {
                    Text("Тут з'явиться твій запис...")
                        .foregroundColor(.gray)
                        .padding()
                }

                QuoteSection(quote: quoteOfTheDay)

                Spacer()
                
                // Навігація тепер передається з батьківського View, тому тут її прибираємо,
                // або залишаємо як декорацію, але краще прибрати, щоб не дублювати.
            }
        }
        .sheet(isPresented: $isEditSheetPresented) {
            if let note = editingNote {
                EditNoteSheet(note: note)
            }
        }
        .onAppear {
            if let existingNote = todayNote {
                selectedMood = existingNote.moodIndex
            }
        }
    }

    private func moodImage(for index: Int?) -> String {
        index.map { MoodAssets.cats[$0] } ?? "calm_cat"
    }

    private func saveNote() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let newNote = MoodNote(moodIndex: selectedMood, text: text)
        modelContext.insert(newNote)
        
        inputText = ""
        isInputFocused = false
    }

    private func editNote(_ note: MoodNote) {
        editingNote = note
        isEditSheetPresented = true
    }

    private func deleteNote(_ note: MoodNote) {
        modelContext.delete(note)
        selectedMood = nil
    }
}

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
                onSave()
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.white)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}

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

struct EditNoteSheet: View {
    @Bindable var note: MoodNote
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
                        onSave: { dismiss() }
                    )
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

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