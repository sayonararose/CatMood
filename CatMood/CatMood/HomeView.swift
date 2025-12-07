//
//  HomeView.swift
//  CatMood
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // Підключаємо базу даних
    @Environment(\.modelContext) private var modelContext
    // Завантажуємо записи (свіжі зверху)
    @Query(sort: \MoodNote.date, order: .reverse) private var notes: [MoodNote]

    @Binding var selectedTab: Int // Зв'язок з навігацією

    // ЛОКАЛЬНИЙ СТАН (для миттєвої реакції інтерфейсу)
    @State private var currentMoodIndex: Int? = nil
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    // СТАН РЕДАГУВАННЯ
    @State private var noteToEdit: MoodNote? = nil

    // Знаходимо запис за сьогодні
    private var todayNote: MoodNote? {
        let calendar = Calendar.current
        return notes.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    // Цитата дня
    private var quoteOfTheDay: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return MoodAssets.quotes[(dayOfYear - 1) % MoodAssets.quotes.count]
    }

    // Якого кота показувати (миттєве оновлення)
    private var displayedBigCat: String? {
        if let index = currentMoodIndex {
            return MoodAssets.cats[index]
        }
        return nil // Показуємо порожній стан
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

                // ВЕЛИКИЙ КІТ або ПОРОЖНІЙ СТАН
                if let catImage = displayedBigCat {
                    Image(catImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .shadow(radius: 10)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 1.2).combined(with: .opacity)
                        ))
                        .id(currentMoodIndex)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentMoodIndex)
                } else {
                    EmptyMoodState()
                }

                // ВИБІР НАСТРОЮ
                MoodSelector(selectedMood: $currentMoodIndex)
                    .onChange(of: currentMoodIndex) { _, _ in
                        saveOrUpdateNote()
                    }

                SectionHeader(icon: "heart.text.square.fill", text: "Твій настрій сьогодні")

                // Якщо запис є - показуємо картку, якщо ні - поле вводу
                if let note = todayNote, !note.text.isEmpty {
                    NoteCard(
                        note: note,
                        onEdit: {
                            // Відкриваємо вікно редагування
                            noteToEdit = note
                        },
                        onDelete: {
                            deleteNote(note)
                        }
                    )
                    .padding(.horizontal)
                } else {
                    InputField(text: $inputText, isFocused: $isInputFocused, currentMood: currentMoodIndex) {
                        saveOrUpdateNote()
                    }
                }

                QuoteSection(quote: quoteOfTheDay)

                Spacer()
            }
        }
        // Завантажуємо дані при старті
        .onAppear {
            if let existingNote = todayNote {
                currentMoodIndex = existingNote.moodIndex
                inputText = existingNote.text
            }
        }
        // Вікно редагування
        .sheet(item: $noteToEdit) { note in
            EditNoteSheet(note: note)
                .presentationBackground(.black)
                .onDisappear {
                    // Оновлюємо головний екран після закриття редагування
                    currentMoodIndex = note.moodIndex
                    inputText = note.text
                }
        }
    }

    // --- ФУНКЦІЇ ---

    private func saveOrUpdateNote() {
        if let existingNote = todayNote {
            existingNote.moodIndex = currentMoodIndex
            if !inputText.isEmpty { existingNote.text = inputText }
            existingNote.date = Date()
        } else {
            let newNote = MoodNote(moodIndex: currentMoodIndex, text: inputText)
            modelContext.insert(newNote)
        }
    }

    private func deleteNote(_ note: MoodNote) {
        HapticManager.shared.warning()

        withAnimation {
            modelContext.delete(note)
            currentMoodIndex = nil
            inputText = ""
        }
    }
}

// --- КОМПОНЕНТИ ---

struct EmptyMoodState: View {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow.opacity(isPulsing ? 0.5 : 1.0))
                .scaleEffect(isPulsing ? 0.9 : 1.0)
                .onAppear {
                    guard !reduceMotion else { return }

                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }

            Text("Оберіть свій настрій сьогодні")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 200)
    }
}

struct MoodSelector: View {
    @Binding var selectedMood: Int?

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<MoodAssets.catsSmall.count, id: \.self) { index in
                let isSelected = selectedMood == index
                VStack(spacing: 4) {
                    Image(isSelected ? MoodAssets.catsPressed[index] : MoodAssets.catsSmall[index])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .scaleEffect(isSelected ? 1.25 : 1.0)
                        .shadow(color: isSelected ? .yellow.opacity(0.5) : .clear, radius: 8)
                        .onTapGesture {
                            HapticManager.shared.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedMood = index
                            }
                        }

                    Text(MoodAssets.moodNames[index])
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .yellow : .white.opacity(0.7))
                        .lineLimit(2)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical)
    }
}

struct InputField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let currentMood: Int?
    let onSave: () -> Void
    @State private var isSaving = false

    var body: some View {
        HStack {
            TextField(MoodAssets.getPrompt(for: currentMood), text: $text)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .focused(isFocused)
                .submitLabel(.done)
                .onSubmit(onSave)

            Button {
                HapticManager.shared.medium()

                isSaving = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isSaving = false
                }

                onSave()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
            }
            .scaleEffect(isSaving ? 1.2 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isSaving)
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
        VStack(alignment: .center, spacing: 4) {
            Text("Цитата дня:")
                .font(.caption)
                .foregroundColor(.gray)
            Text(quote)
                .font(.body)
                .italic()
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// ВИПРАВЛЕНА КАРТКА (сама визначає картинку)
struct NoteCard: View {
    let note: MoodNote
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            if let idx = note.moodIndex {
                Image(MoodAssets.catsSmall[idx])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading) {
                Text(note.text)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: 15) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(16)
    }
}

// ВІКНО РЕДАГУВАННЯ
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

                    TextEditSection(text: $note.text, isFocused: $isFocused, moodIndex: note.moodIndex)
                    
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
        HStack(spacing: 16) {
            ForEach(0..<MoodAssets.catsSmall.count, id: \.self) { index in
                let isSelected = selectedMood == index
                VStack(spacing: 4) {
                    Image(isSelected ? MoodAssets.catsPressed[index] : MoodAssets.catsSmall[index])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .shadow(color: isSelected ? .yellow.opacity(0.5) : .clear, radius: 6)
                        .onTapGesture {
                            HapticManager.shared.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedMood = index
                            }
                        }

                    Text(MoodAssets.moodNames[index])
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .yellow : .white.opacity(0.7))
                        .lineLimit(2)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
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
    let moodIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Опис:")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                Spacer()

                if moodIndex != nil {
                    Text(MoodAssets.getPrompt(for: moodIndex))
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.6))
                        .italic()
                }
            }

            ZStack(alignment: .topLeading) {
                Color.white.opacity(0.1)
                    .cornerRadius(12)

                TextEditor(text: $text)
                    .padding(10)
                    .foregroundColor(.white)
                    .focused(isFocused)
                    .scrollContentBackground(.hidden)
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
            Button("Скасувати") {
                HapticManager.shared.light()
                onCancel()
            }
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            Button("Зберегти") {
                HapticManager.shared.success()
                onSave()
            }
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}
