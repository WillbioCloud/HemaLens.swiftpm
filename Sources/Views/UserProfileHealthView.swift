import SwiftUI

// MARK: - My Blood & Watch Sync View (Tab 3)
struct UserProfileHealthView: View {
    @ObservedObject var viewModel: LabViewModel
    
    // User Blood Exam Form State
    @State private var inputRBC: String = "5.0"
    @State private var inputWBC: String = "7500"
    @State private var inputPLT: String = "280000"
    @State private var inputGlucose: String = "88"
    @State private var validationBanner: String? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("APPLE HEALTH & WATCH TELEMETRY")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(.cyan)
                    
                    Text("My Blood & Watch Sync")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Correlate Apple Watch cardio-respiratory telemetry with your real complete blood count & glycemia.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 1. Apple Health / Watch Bento Metrics
                watchTelemetryGrid
                
                // 2. Synced Apple Watch Profiles
                watchProfilesSection
                
                // 3. Personal Blood Test Form
                personalExamFormSection
            }
            .padding(20)
            .padding(.bottom, 90) // Clearance for floating bottom tab bar
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.05, blue: 0.10), Color(red: 0.03, green: 0.03, blue: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            syncFormWithCurrentViewModel()
        }
    }
    
    // MARK: - 1. Apple Watch Telemetry Bento Grid
    private var watchTelemetryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Live Physiological Sync", systemImage: "applewatch.watchface")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let profile = viewModel.activeWatchProfile {
                    Text(profile.profileName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(profile.accentColor.opacity(0.22))
                        .foregroundStyle(profile.accentColor)
                        .clipShape(Capsule())
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                bentoCard(
                    icon: "heart.fill",
                    color: .red,
                    title: "Heart Rate",
                    value: "\(viewModel.heartRateBPM)",
                    unit: "BPM"
                )
                
                bentoCard(
                    icon: "lungs.fill",
                    color: .cyan,
                    title: "Blood Oxygen",
                    value: "\(viewModel.estimatedSpO2)",
                    unit: "% SpO2"
                )
                
                bentoCard(
                    icon: "flame.fill",
                    color: .green,
                    title: "Daily Exercise",
                    value: "\(viewModel.dailyExerciseMinutes)",
                    unit: "min"
                )
                
                bentoCard(
                    icon: "figure.run",
                    color: .mint,
                    title: "VO2 Max",
                    value: String(format: "%.1f", viewModel.vo2Max),
                    unit: "mL/kg/min"
                )
                
                bentoCard(
                    icon: "bed.double.fill",
                    color: .indigo,
                    title: "Sleep",
                    value: String(format: "%.1f", viewModel.sleepHours),
                    unit: "hours"
                )
                
                bentoCard(
                    icon: "cube.fill",
                    color: .orange,
                    title: "Est. HbA1c",
                    value: String(format: "%.1f", viewModel.estimatedHbA1c),
                    unit: "% (Glycated)"
                )
            }
        }
    }
    
    // MARK: - 2. Watch Profiles Switcher
    private var watchProfilesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIMULATED WATCH PROFILES")
                .font(.caption2.weight(.heavy))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            
            ForEach(WatchSyncProfile.profiles) { profile in
                let isSelected = viewModel.activeWatchProfile == profile
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: profile.badgeIcon)
                            .font(.headline)
                            .foregroundStyle(profile.accentColor)
                            .frame(width: 34, height: 34)
                            .background(profile.accentColor.opacity(0.18))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(profile.profileName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(profile.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.applyWatchProfile(profile)
                            syncFormWithCurrentViewModel()
                        } label: {
                            Text(isSelected ? "Synced" : "Sync")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? profile.accentColor : Color.white.opacity(0.14))
                                .foregroundStyle(isSelected ? Color.black : Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(profile.healthSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isSelected {
                        Button {
                            withAnimation(.spring()) {
                                viewModel.activeMainTab = .lab3D
                            }
                        } label: {
                            Label("Open in 3D Vein & Body View", systemImage: "arrow.right.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(profile.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(isSelected ? profile.accentColor.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1.2)
                )
            }
        }
    }
    
    // MARK: - 3. Real Lab Exam Input Form
    private var personalExamFormSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label("Enter Your Real Blood Test Results", systemImage: "doc.text.magnifyingglass")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Type your own CBC and fasting glucose numbers from a lab report to inspect them inside your 3D vein and body.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 10) {
                examInputRow(
                    title: "Red Blood Cells (RBC)",
                    unit: "million/µL (Normal: 4.5–5.9)",
                    icon: "drop.fill",
                    color: .red,
                    text: $inputRBC
                )
                
                examInputRow(
                    title: "White Blood Cells (WBC)",
                    unit: "/µL (Normal: 4,500–11,000)",
                    icon: "shield.lefthalf.filled",
                    color: .cyan,
                    text: $inputWBC
                )
                
                examInputRow(
                    title: "Platelets (PLT)",
                    unit: "/µL (Normal: 150,000–450,000)",
                    icon: "bandage.fill",
                    color: .yellow,
                    text: $inputPLT
                )
                
                examInputRow(
                    title: "Blood Glucose",
                    unit: "mg/dL (Normal: 70–99)",
                    icon: "cube.fill",
                    color: .mint,
                    text: $inputGlucose
                )
            }
            
            if let message = validationBanner {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            
            Button {
                submitPersonalExam()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "viewfinder.circle.fill")
                    Text("Visualize My Blood in 3D")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.cyan.opacity(0.35), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Subviews & Helpers
    @ViewBuilder
    private func bentoCard(icon: String, color: Color, title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(color.opacity(0.28), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func examInputRow(title: String, unit: String, icon: String, color: Color, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.16))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.bold))
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            TextField("Value", text: text)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 96)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func syncFormWithCurrentViewModel() {
        inputRBC = String(format: "%.1f", viewModel.rbcCount)
        inputWBC = "\(Int(viewModel.wbcCount))"
        inputPLT = "\(Int(viewModel.pltCount))"
        inputGlucose = "\(Int(viewModel.glucoseLevel))"
    }
    
    private func submitPersonalExam() {
        let normalizedRBC = inputRBC.replacingOccurrences(of: ",", with: ".")
        let normalizedWBC = inputWBC.replacingOccurrences(of: ",", with: "")
        let normalizedPLT = inputPLT.replacingOccurrences(of: ",", with: "")
        let normalizedGLU = inputGlucose.replacingOccurrences(of: ",", with: ".")
        
        guard let rbc = Double(normalizedRBC),
              let wbc = Double(normalizedWBC),
              let plt = Double(normalizedPLT),
              let glu = Double(normalizedGLU) else {
            validationBanner = "Please enter valid numeric values for all 4 parameters."
            return
        }
        
        validationBanner = nil
        viewModel.applyPersonalBloodExam(rbc: rbc, wbc: wbc, plt: plt, glucose: glu)
    }
}

