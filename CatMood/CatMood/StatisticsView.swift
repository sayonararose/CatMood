//
//  StatisticsView.swift
//  CatMood
//

import SwiftUI
import SwiftData
import Charts 

struct StatisticsView: View {
    @Query private var notes: [MoodNote]

    @State private var selectedMonth: Date = Date()
    private let calendar = Calendar.current

    enum TrendDirection {
        case up, down, neutral
    }

    var selectedMonthNotes: [MoodNote] {
        return notes.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    var previousMonthNotes: [MoodNote] {
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return []
        }
        return notes.filter { calendar.isDate($0.date, equalTo: prevMonth, toGranularity: .month) }
    }

    var moodCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for note in selectedMonthNotes {
            if let index = note.moodIndex {
                counts[index, default: 0] += 1
            }
        }
        return counts
    }

    var monthComparison: (percentage: Int, trend: TrendDirection)? {
        let currentCount = selectedMonthNotes.count
        let previousCount = previousMonthNotes.count

        guard previousCount > 0 else { return nil }

        let change = currentCount - previousCount
        let percentage = Int((Double(change) / Double(previousCount)) * 100)

        let trend: TrendDirection = change > 0 ? .up : (change < 0 ? .down : .neutral)
        return (percentage, trend)
    }

    var currentStreak: Int {
        let sortedNotes = selectedMonthNotes
            .filter { $0.moodIndex == 2 || $0.moodIndex == 3 }
            .sorted { $0.date < $1.date }

        guard !sortedNotes.isEmpty else { return 0 }

        var streak = 1
        var maxStreak = 1

        for i in 1..<sortedNotes.count {
            let prevDate = sortedNotes[i - 1].date
            let currentDate = sortedNotes[i].date

            if let dayDiff = calendar.dateComponents([.day], from: prevDate, to: currentDate).day,
               dayDiff == 1 {
                streak += 1
                maxStreak = max(maxStreak, streak)
            } else {
                streak = 1
            }
        }

        return maxStreak
    }

    var mostCommonMood: (index: Int, count: Int)? {
        guard !moodCounts.isEmpty else { return nil }

        return moodCounts.max { $0.value < $1.value }
            .map { ($0.key, $0.value) }
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

                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow)
                    }

                    Text(monthYearString(from: selectedMonth))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200)

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(isCurrentMonth() ? .gray : .yellow)
                    }
                    .disabled(isCurrentMonth())
                }
                .padding(.horizontal)

                if selectedMonthNotes.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Немає записів у цьому місяці")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            if let comparison = monthComparison {
                                let color: Color = comparison.trend == .up ? .green : (comparison.trend == .down ? .red : .yellow)
                                let icon = comparison.trend == .up ? "chart.line.uptrend.xyaxis" : (comparison.trend == .down ? "chart.line.downtrend.xyaxis" : "minus.circle")
                                let sign = comparison.percentage > 0 ? "+" : ""

                                InsightCard(
                                    icon: icon,
                                    iconColor: color,
                                    title: "Порівняно з минулим місяцем",
                                    value: "\(sign)\(comparison.percentage)% записів"
                                )
                            } else {
                                InsightCard(
                                    icon: "calendar",
                                    iconColor: .gray,
                                    title: "Порівняно з минулим місяцем",
                                    value: "Немає даних для порівняння"
                                )
                            }

                            if currentStreak > 0 {
                                InsightCard(
                                    icon: "flame.fill",
                                    iconColor: .orange,
                                    title: "Позитивна серія",
                                    value: "🔥 \(currentStreak) \(streakText(currentStreak))"
                                )
                            } else {
                                InsightCard(
                                    icon: "sparkles",
                                    iconColor: .yellow,
                                    title: "Позитивна серія",
                                    value: "Почніть нову серію!"
                                )
                            }

                            if let common = mostCommonMood {
                                HStack(spacing: 16) {
                                    Image(MoodAssets.catsSmall[common.index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Найчастіший настрій")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        Text("\(MoodAssets.moodNames[common.index]) (\(common.count) \(daysText(common.count)))")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(.white)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }

                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 10)

                            Text("Розподіл настроїв")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(0..<MoodAssets.cats.count, id: \.self) { index in
                                let count = moodCounts[index] ?? 0
                                let total = selectedMonthNotes.count
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

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            if newDate <= Date() || value < 0 {
                selectedMonth = newDate
            }
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    private func isCurrentMonth() -> Bool {
        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func streakText(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100

        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "днів поспіль"
        }

        switch lastDigit {
        case 1:
            return "день поспіль"
        case 2, 3, 4:
            return "дні поспіль"
        default:
            return "днів поспіль"
        }
    }

    private func daysText(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100

        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "днів"
        }

        switch lastDigit {
        case 1:
            return "день"
        case 2, 3, 4:
            return "дні"
        default:
            return "днів"
        }
    }
}

struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
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