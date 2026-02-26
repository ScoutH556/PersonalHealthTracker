import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    // Track focus so we can dismiss the keyboard without relying on a keyboard "Done" button
    private enum Field: Hashable {
        case heightFeet, heightInches, weight
    }
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    // HEIGHT
                    HStack {
                        Text("Height")
                        Spacer()

                        TextField("ft", value: bind(\.heightFeet), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                            .focused($focusedField, equals: .heightFeet)

                        Text("ft")

                        TextField("in", value: bind(\.heightInches), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                            .focused($focusedField, equals: .heightInches)

                        Text("in")

                        // Inline Done button for number pads (no return key)
                        if focusedField == .heightFeet || focusedField == .heightInches {
                            Button("Done") { focusedField = nil }
                                .font(.callout)
                        }
                    }

                    // WEIGHT
                    HStack {
                        Text("Weight (lb)")
                        Spacer()

                        TextField("118", value: bind(\.weightLbs), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .focused($focusedField, equals: .weight)

                        // Inline Done button for decimal pad (no return key)
                        if focusedField == .weight {
                            Button("Done") { focusedField = nil }
                                .font(.callout)
                        }
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
            // Lets the user swipe down to dismiss the keyboard as a backup
            .scrollDismissesKeyboard(.interactively)
            // Tap anywhere in the form to dismiss (another reliable backup)
            .onTapGesture { focusedField = nil }
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
