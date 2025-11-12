//
//  ContentView.swift
//  CatMood
//
//  Created on 06.11.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedMood: Int? = nil
    @State private var customMood: String = ""

    let moods = ["😔", "😠", "😌", "😎", "😋"]
    let quoteOfTheDay = "Варто тільки повірити, що ви можете — і ви вже на півдорозі до цілі"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // Заголовок
                Text("Який настрій у тебе сьогодні?")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 50)

                // Зображення котика
                Image("happyCat") // додай свій котик у Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .shadow(radius: 10)

                // Емоджі-настрої
                HStack(spacing: 20) {
                    ForEach(moods.indices, id: \.self) { index in
                        Text(moods[index])
                            .font(.system(size: 40))
                            .opacity(selectedMood == index ? 1.0 : 0.5)
                            .scaleEffect(selectedMood == index ? 1.2 : 1.0)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedMood = index
                                }
                            }
                    }
                }

                // Поле для введення власного настрою
                HStack {
                    TextField("Напишіть про свій настрій...", text: $customMood)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.white)
                }
                .passing(.horizontal)

                // Цитата дня
                VStack(alignment: .leading, spacing: 4) {
                    Text("Цитата дня:")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Text(quoteOfTheDay)
                        .foregroundColor(.white)
                        .font(.body)
                }
                .padding(.horizontal)

                Spacer()

                // Нижня панель навігації
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
    }
}

#Preview {
    ContentView()
}
