import SwiftUI

// MARK: - Onboarding Modal View
/// Glassmorphic introductory modal explaining the biomedical mission,
/// the 4 blood biomarkers, Micro/Macro 3D visualization, and 3-tab lab experience.
struct OnboardingModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 16) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 54, height: 54)
                                    .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 4)
                                
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            HStack(spacing: 6) {
                                Text("HemaLens")
                                    .font(.title.weight(.heavy))
                                    .foregroundStyle(.primary)
                                Text("2.0")
                                    .font(.caption.weight(.heavy))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.red.opacity(0.25))
                                    .foregroundStyle(.red)
                                    .clipShape(Capsule())
                            }
                            
                            Text("Blood Lab & 3D Body Physiology")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Mission Statement
                        Text("\"Exams are full of cryptic numbers. Let's look inside the vein and across the body to see what they actually mean.\"")
                            .font(.callout.italic())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary.opacity(0.95))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        // 4 Biomarkers Overview
                        VStack(spacing: 8) {
                            lineageRow(
                                icon: "drop.fill",
                                color: .red,
                                title: "Erythrocytes (RBC)",
                                subtitle: "Oxygen Carriers",
                                detail: "Biconcave discs governing arterial oxygen saturation, pulse rate, and blood viscosity."
                            )
                            
                            lineageRow(
                                icon: "shield.lefthalf.filled",
                                color: .cyan,
                                title: "Leukocytes (WBC)",
                                subtitle: "Immune Sentinels",
                                detail: "Textured sentries patrolling vessel walls. Infection triggers soft cytokine aura flares."
                            )
                            
                            lineageRow(
                                icon: "bandage.fill",
                                color: .yellow,
                                title: "Platelets (PLT)",
                                subtitle: "Clotting Responders",
                                detail: "Biconvex golden fragments that aggregate and form fibrin networks when elevated."
                            )
                            
                            lineageRow(
                                icon: "cube.fill",
                                color: .mint,
                                title: "Blood Glucose",
                                subtitle: "Metabolic Fuel",
                                detail: "Above 140 mg/dL, sugar crystals flood plasma, slow flow, and darken glycated vessels."
                            )
                        }
                        
                        // New 2.0 Features Hint
                        HStack(spacing: 12) {
                            hintPill(icon: "figure.stand", text: "3D Macro Body")
                            hintPill(icon: "leaf.fill", text: "Nutrition Tracker")
                            hintPill(icon: "applewatch.watchface", text: "Watch Sync")
                        }
                    }
                }
                
                // CTA Button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } label: {
                    Text("Enter the Bloodstream")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 520, maxHeight: 620)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.red.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
            .padding(18)
        }
    }
    
    @ViewBuilder
    private func lineageRow(icon: String, color: Color, title: String, subtitle: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.18))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("• \(subtitle)")
                        .font(.caption2)
                        .foregroundStyle(color)
                }
                
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    @ViewBuilder
    private func hintPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.cyan)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}
