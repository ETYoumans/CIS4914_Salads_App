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
                    HStack {
                            Text("Sensitivity Level")
                            Spacer()
                            Text("\(sensitivityLevel)")
                                .fontWeight(.semibold)
                        }
                    Slider(
                        value: Binding(
                            get: { Double(sensitivityLevel) },
                            set: { sensitivityLevel = Int($0) }
                        ),
                        in: 0...300,
                        step: 1
                    )

                    HStack {
                        Text("0")
                        Spacer()
                        Text("300")
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
