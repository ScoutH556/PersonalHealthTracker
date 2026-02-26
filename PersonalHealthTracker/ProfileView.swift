import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("ft", value: bind(\.heightFeet), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)

                        Text("ft")

                        TextField("in", value: bind(\.heightInches), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)

                        Text("in")
                    }

                    HStack {
                        Text("Weight (lb)")
                        Spacer()
                        TextField("118", value: bind(\.weightLbs), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }

                    Picker("Sex", selection: bind(\.sex)) {
                        ForEach(Sex.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized).tag(s)
                        }
                    }
                }

                Section("Caffeine factors") {
                    Toggle("Oral contraceptives", isOn: bind(\.usesOralContraceptives))
                    Toggle("Smoker", isOn: bind(\.smoker))

                    Text("These factors adjust the estimated caffeine half-life automatically.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
        }
        .onAppear {
            if profiles.isEmpty {
                modelContext.insert(UserProfile())
            }
        }
    }

    private var profile: UserProfile {
        profiles.first ?? UserProfile()
    }

    private func bind<T>(_ keyPath: ReferenceWritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { profile[keyPath: keyPath] = $0 }
        )
    }
}
