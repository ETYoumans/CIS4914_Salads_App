import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var alertSoundEnabled = true
    @State private var vibrationEnabled = true
    @State private var sensitivityLevel = 2
    @State private var selectedSound = "Default"

    let soundOptions = ["Default", "Chime", "Alert", "Silent"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            Group {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)

                Toggle("Play Alert Sound", isOn: $alertSoundEnabled)
                    .disabled(!notificationsEnabled)

                Picker("Alert Sound", selection: $selectedSound) {
                    ForEach(soundOptions, id: \.self) { sound in
                        Text(sound)
                    }
                }
                .disabled(!alertSoundEnabled || !notificationsEnabled)

                Toggle("Enable Vibration", isOn: $vibrationEnabled)
                    .disabled(!notificationsEnabled)

                VStack(alignment: .leading) {
                    Text("Sensitivity Level")
                    Slider(value: Binding(
                        get: { Double(sensitivityLevel) },
                        set: { sensitivityLevel = Int($0) }
                    ), in: 1...10, step: 1)
                    HStack {
                        Text("Low")
                        Spacer()
                        Text("High")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

