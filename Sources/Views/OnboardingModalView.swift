import SwiftUI

// MARK: - Onboarding Modal View
/// Glassmorphic introductory modal (0:00–0:30 minute flow) explaining
/// the biomedical mission, the 3 blood cell lineages, and how to interact with the 3D vessel.
struct OnboardingModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Blurred dimmed background
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Central Card
            VStack(spacing: 20) {
                // Header: Logo & Badge
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 4)
                        
                        Image(systemName: "drop.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("HemaLens")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Complete Blood Count (CBC) Unpacked")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                // Mission Statement (Section 6 SDD)
                Text("\"Exams are full of cryptic numbers. Let's look inside the vein to see what they actually mean.\"")
                    .font(.callout.italic())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // 3 Cell Lineages Overview
                VStack(spacing: 10) {
                    lineageRow(
                        icon: "drop.fill",
                        color: .red,
                        title: "Erythrocytes (RBC)",
                        subtitle: "Oxygen Carriers",
                        detail: "Biconcave discs packed with hemoglobin. Their abundance governs plasma viscosity and vivid arterial redness."
                    )
                    
                    lineageRow(
                        icon: "shield.lefthalf.filled",
                        color: .cyan,
                        title: "Leukocytes (WBC)",
                        subtitle: "Immune Sentinels",
                        detail: "Sentinel spheres patrolling endothelial walls. During active infection, they release glowing cytokine flares."
                    )
                    
                    lineageRow(
                        icon: "bandage.fill",
                        color: .yellow,
                        title: "Platelets (PLT)",
                        subtitle: "Clotting Responders",
                        detail: "Minute golden discoid fragments. High concentrations trigger platelet aggregation and insoluble fibrin threads."
                    )
                }
                
                // Interactive Hints
                HStack(spacing: 16) {
                    hintPill(icon: "hand.draw.fill", text: "Drag 3D to rotate")
                    hintPill(icon: "hand.tap.fill", text: "Tap cells to inspect")
                    hintPill(icon: "slider.horizontal.3", text: "Move sliders to test")
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
            .padding(24)
            .frame(maxWidth: 520)
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
            .padding(20)
        }
    }
    
    @ViewBuilder
    private func lineageRow(icon: String, color: Color, title: String, subtitle: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
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
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    @ViewBuilder
    private func hintPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

