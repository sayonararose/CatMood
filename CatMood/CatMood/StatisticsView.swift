//
//  StatisticsView.swift
//  CatMood
//

import SwiftUI
import SwiftData
import Charts 

struct StatisticsView: View {
    @Query private var notes: [MoodNote]
    
    // Отримуємо поточний місяць
    var currentMonthNotes: [MoodNote] {
        let calendar = Calendar.current
        let now = Date()
        return notes.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
    
    // Рахуємо статистику: [Індекс настрою : Кількість]
    var moodCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for note in currentMonthNotes {
            if let index = note.moodIndex {
                counts[index, default: 0] += 1
            }
        }
        return counts
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Статистика за місяць")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                if currentMonthNotes.isEmpty {
                    Spacer()
                    Text("Поки що немає записів у цьому місяці")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // Графік
                    ScrollView {
                        VStack(spacing: 25) {
                            ForEach(0..<MoodAssets.cats.count, id: \.self) { index in
                                let count = moodCounts[index] ?? 0
                                let total = currentMonthNotes.count
                                let percentage = total > 0 ? Double(count) / Double(total) : 0
                                
                                MoodBarRow(moodIndex: index, count: count, percentage: percentage)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// Окремий рядок графіка (Мордочка + Смужка + Кількість)
struct MoodBarRow: View {
    let moodIndex: Int
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack {
            // Картинка
            Image(MoodAssets.catsSmall[moodIndex])
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            // Смужка графіка
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон смужки
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 20)
                    
                    // Заповнена частина
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow)
                        .frame(width: geometry.size.width * percentage, height: 20)
                        .animation(.spring(), value: percentage)
                }
            }
            .frame(height: 20)
            
            // Цифра
            Text("\(count)")
                .bold()
                .foregroundColor(.white)
                .frame(width: 30)
        }
    }
}