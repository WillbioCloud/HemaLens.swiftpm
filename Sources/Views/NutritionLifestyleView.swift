import SwiftUI

// MARK: - Nutrition & Lifestyle View (Tab 2)
struct NutritionLifestyleView: View {
    @ObservedObject var viewModel: LabViewModel
    @State private var selectedSection: NutritionSection = .tracker
    @State private var catalogFilter: CatalogFilter = .all
    
    enum NutritionSection: String, CaseIterable, Identifiable {
        case tracker = "Daily Tracker"
        case timeline = "Sugar Timeline"
        case catalog = "Food Guide"
        
        var id: String { rawValue }
    }
    
    enum CatalogFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case builders = "Blood Builders"
        case villains = "Blood Villains"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("NUTRITION & VASCULAR LIFESTYLE")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(.green)
                    
                    Text("Fueling Your Bloodstream")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Simulate how nutrients, hydration, refined sugar, and sitting shape your blood cells and vessels.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(NutritionSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                
                // Active Section Content
                switch selectedSection {
                case .tracker:
                    dailyTrackerSection
                case .timeline:
                    sugarTimelineSection
                case .catalog:
                    educationalCatalogSection
                }
            }
            .padding(20)
            .padding(.bottom, 90) // Clearance for floating bottom tab bar
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.07), Color(red: 0.03, green: 0.03, blue: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    // MARK: - 1. Interactive Daily Tracker
    private var dailyTrackerSection: some View {
        let projected = viewModel.projectedDietValues
        
        return VStack(alignment: .leading, spacing: 14) {
            // Live Projected Blood Preview Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Projected Bloodstream Impact", systemImage: "waveform.path.ecg")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !viewModel.dailyIntake.isEmpty {
                        Button("Clear") {
                            withAnimation(.spring()) {
                                viewModel.clearDailyIntake()
                            }
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    }
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    projectedMetricPill(type: .erythrocytes, value: projected.rbc)
                    projectedMetricPill(type: .leukocytes, value: projected.wbc)
                    projectedMetricPill(type: .platelets, value: projected.plt)
                    projectedMetricPill(type: .glucose, value: projected.glucose)
                }
                
                Button {
                    viewModel.applyDietToBloodstream()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.triangle.fill")
                        Text("Apply Diet to 3D Bloodstream")
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.green.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
            )
            
            // Tracker Items List
            Text("LOG TODAY'S INTAKE & HABITS")
                .font(.caption2.weight(.heavy))
                .tracking(1.1)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            
            ForEach(FoodHabitItem.catalog) { item in
                let count = viewModel.dailyIntake[item.id] ?? 0
                let totalQty = Double(count) * item.defaultStepAmount
                let exceeds = item.category == .bloodVillains && totalQty > item.safeDailyLimit && count > 0
                
                HStack(spacing: 12) {
                    Image(systemName: item.iconName)
                        .font(.headline)
                        .foregroundStyle(item.category.color)
                        .frame(width: 38, height: 38)
                        .background(item.category.color.opacity(0.16))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            if exceeds {
                                Text("OVER LIMIT")
                                    .font(.system(size: 9, weight: .heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.28))
                                    .foregroundStyle(.red)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text("\(item.unitLabel) • \(item.limitDescription)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        if count > 0 {
                            Text("Logged: \(Int(totalQty)) (\(count)x)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(exceeds ? .red : item.category.color)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                viewModel.removeIntakeServing(for: item)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(count > 0 ? .secondary : .secondary.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(count == 0)
                        
                        Text("\(count)")
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                            .frame(minWidth: 20)
                        
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                viewModel.addIntakeServing(for: item)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(item.category.color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(exceeds ? Color.red.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - 2. Sugar & Sedentary Timeline
    private var sugarTimelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Sugar & Sedentary Time-Course", systemImage: "clock.arrow.circlepath")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.orange)
                
                Text("What happens inside your bloodstream from the first 15 minutes after a sugary snack + sitting to years of chronic exposure.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(MetabolicTimelineMilestone.milestones) { milestone in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: milestone.iconName)
                            .font(.headline)
                            .foregroundStyle(milestone.accentColor)
                            .frame(width: 34, height: 34)
                            .background(milestone.accentColor.opacity(0.18))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(milestone.timeframe.uppercased())
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(milestone.accentColor)
                            Text(milestone.headline)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(milestone.mechanism)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundStyle(milestone.accentColor)
                            .padding(.top, 2)
                        Text("3D Effect: \(milestone.visualImpactSummary)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(milestone.accentColor.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - 3. Educational Catalog (Blood Builders vs. Villains)
    private var educationalCatalogSection: some View {
        let filteredItems = FoodHabitItem.catalog.filter { item in
            switch catalogFilter {
            case .all: return true
            case .builders: return item.category == .bloodBuilders
            case .villains: return item.category == .bloodVillains
            }
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Picker("Filter", selection: $catalogFilter) {
                ForEach(CatalogFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            
            ForEach(filteredItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.iconName)
                            .font(.subheadline)
                            .foregroundStyle(item.category.color)
                            .frame(width: 30, height: 30)
                            .background(item.category.color.opacity(0.18))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.subheadline.weight(.bold))
                            Text(item.nutrientTag)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(item.category.color)
                        }
                        
                        Spacer()
                        
                        Text(item.category.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(item.category.color.opacity(0.18))
                            .foregroundStyle(item.category.color)
                            .clipShape(Capsule())
                    }
                    
                    Text(item.physiologicalEffect)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(item.limitDescription)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(item.category.color.opacity(0.32), lineWidth: 1)
                )
            }
        }
    }
    
    @ViewBuilder
    private func projectedMetricPill(type: BloodCellType, value: Double) -> some View {
        let status = type.status(for: value)
        HStack {
            Image(systemName: type.iconName)
                .font(.caption)
                .foregroundStyle(type.themeColor)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(type.shortName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(type.formattedValue(value)) \(type.unit)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(status.color)
            }
            Spacer()
        }
        .padding(9)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
