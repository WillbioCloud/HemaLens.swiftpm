import Foundation
import SwiftUI

// MARK: - Nutrition Category
enum NutritionCategory: String, CaseIterable, Identifiable {
    case bloodBuilders = "Blood Builders"
    case bloodVillains = "Blood Villains"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .bloodBuilders: return .green
        case .bloodVillains: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .bloodBuilders: return "leaf.fill"
        case .bloodVillains: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Food & Lifestyle Item
struct FoodHabitItem: Identifiable, Equatable {
    let id: String
    let name: String
    let category: NutritionCategory
    let nutrientTag: String
    let iconName: String
    let unitLabel: String
    let defaultStepAmount: Double
    let safeDailyLimit: Double
    let limitDescription: String
    let physiologicalEffect: String
    
    // Biomedical impacts per standard unit/serving
    let rbcDeltaPerServing: Double
    let wbcDeltaPerServing: Double
    let pltDeltaPerServing: Double
    let glucoseDeltaPerServing: Double
    
    static let catalog: [FoodHabitItem] = [
        // MARK: Blood Builders
        FoodHabitItem(
            id: "heme_iron",
            name: "Lean Beef / Lentils",
            category: .bloodBuilders,
            nutrientTag: "Heme & Plant Iron",
            iconName: "flame.fill",
            unitLabel: "100g serving",
            defaultStepAmount: 100,
            safeDailyLimit: 250,
            limitDescription: "Target: 100–200g/day (~14–18 mg iron)",
            physiologicalEffect: "Supplies elemental iron core for hemoglobin porphyrin rings, boosting erythrocyte oxygen capacity (+RBC).",
            rbcDeltaPerServing: 0.45,
            wbcDeltaPerServing: 150,
            pltDeltaPerServing: 8000,
            glucoseDeltaPerServing: 2
        ),
        FoodHabitItem(
            id: "vitamin_c",
            name: "Citrus & Bell Peppers",
            category: .bloodBuilders,
            nutrientTag: "Vitamin C (Ascorbate)",
            iconName: "sun.max.fill",
            unitLabel: "100g serving",
            defaultStepAmount: 100,
            safeDailyLimit: 400,
            limitDescription: "Safe target: 100–300g/day",
            physiologicalEffect: "Reduces dietary Fe3+ to absorbable Fe2+ in the duodenum and enhances neutrophil chemotaxis.",
            rbcDeltaPerServing: 0.25,
            wbcDeltaPerServing: 400,
            pltDeltaPerServing: 5000,
            glucoseDeltaPerServing: 4
        ),
        FoodHabitItem(
            id: "b12_folate",
            name: "Salmon, Eggs & Spinach",
            category: .bloodBuilders,
            nutrientTag: "Vitamin B12 & Folate",
            iconName: "sparkles",
            unitLabel: "100g serving",
            defaultStepAmount: 100,
            safeDailyLimit: 300,
            limitDescription: "Target: 100–250g/day",
            physiologicalEffect: "Essential cofactors for marrow DNA thymidine synthesis, preventing megaloblastic anemia and marrow suppression.",
            rbcDeltaPerServing: 0.35,
            wbcDeltaPerServing: 300,
            pltDeltaPerServing: 18000,
            glucoseDeltaPerServing: 1
        ),
        FoodHabitItem(
            id: "pure_water",
            name: "Pure Water Hydration",
            category: .bloodBuilders,
            nutrientTag: "Plasma Volume",
            iconName: "drop.fill",
            unitLabel: "500 mL glass",
            defaultStepAmount: 500,
            safeDailyLimit: 3500,
            limitDescription: "Optimal: 2,000–3,000 mL/day",
            physiologicalEffect: "Expands plasma fluid fraction, lowers hyperviscosity drag, dilutes concentrated glucose, and supports renal clearance.",
            rbcDeltaPerServing: -0.10,
            wbcDeltaPerServing: -200,
            pltDeltaPerServing: -12000,
            glucoseDeltaPerServing: -12
        ),
        FoodHabitItem(
            id: "omega_3",
            name: "Walnuts & Wild Fish",
            category: .bloodBuilders,
            nutrientTag: "Omega-3 EPA / DHA",
            iconName: "heart.circle.fill",
            unitLabel: "30g portion",
            defaultStepAmount: 30,
            safeDailyLimit: 90,
            limitDescription: "Optimal: 30–60g/day",
            physiologicalEffect: "Incorporates into platelet membranes, downregulating TXA2 aggregation and soothing endothelial inflammation.",
            rbcDeltaPerServing: 0.05,
            wbcDeltaPerServing: -600,
            pltDeltaPerServing: -22000,
            glucoseDeltaPerServing: -4
        ),
        FoodHabitItem(
            id: "brisk_walk",
            name: "30-Min Aerobic Walk",
            category: .bloodBuilders,
            nutrientTag: "Insulin Sensitivity",
            iconName: "figure.walk",
            unitLabel: "30 min session",
            defaultStepAmount: 30,
            safeDailyLimit: 120,
            limitDescription: "WHO Target: 30–60 min/day",
            physiologicalEffect: "Translocates GLUT4 glucose transporters to muscle membranes independently of insulin, rapidly clearing excess blood sugar.",
            rbcDeltaPerServing: 0.15,
            wbcDeltaPerServing: -500,
            pltDeltaPerServing: -18000,
            glucoseDeltaPerServing: -32
        ),
        
        // MARK: Blood Villains
        FoodHabitItem(
            id: "refined_sugar",
            name: "Soda & Refined Sweets",
            category: .bloodVillains,
            nutrientTag: "Added Simple Sugar",
            iconName: "cube.fill",
            unitLabel: "35g sugar serving",
            defaultStepAmount: 35,
            safeDailyLimit: 25,
            limitDescription: "AHA Safe Limit: < 25g/day",
            physiologicalEffect: "Triggers rapid glycemic spikes, hyperinsulinemia, HbA1c hemoglobin glycation, and oxidative stiffening of endothelium.",
            rbcDeltaPerServing: 0.0,
            wbcDeltaPerServing: 1800,
            pltDeltaPerServing: 35000,
            glucoseDeltaPerServing: 68
        ),
        FoodHabitItem(
            id: "trans_fats",
            name: "Fried Fast Food",
            category: .bloodVillains,
            nutrientTag: "Trans & Oxidized Fats",
            iconName: "takeoutbag.and.cup.and.straw.fill",
            unitLabel: "150g meal",
            defaultStepAmount: 150,
            safeDailyLimit: 0,
            limitDescription: "Safe limit: 0g industrial trans fat",
            physiologicalEffect: "Provokes acute endothelial cytokine flare (+WBC), LDL oxidation, and heightened platelet adhesiveness.",
            rbcDeltaPerServing: 0.10,
            wbcDeltaPerServing: 2600,
            pltDeltaPerServing: 48000,
            glucoseDeltaPerServing: 28
        ),
        FoodHabitItem(
            id: "excess_sodium",
            name: "Ultra-Processed Snacks",
            category: .bloodVillains,
            nutrientTag: "Excess Sodium (>2g)",
            iconName: "exclamationmark.triangle.fill",
            unitLabel: "100g bag",
            defaultStepAmount: 100,
            safeDailyLimit: 30,
            limitDescription: "WHO Sodium Limit: < 2,000 mg/day",
            physiologicalEffect: "Induces vascular nitric oxide suppression, arterial stiffness, and osmotic blood pressure surges.",
            rbcDeltaPerServing: 0.15,
            wbcDeltaPerServing: 900,
            pltDeltaPerServing: 25000,
            glucoseDeltaPerServing: 18
        ),
        FoodHabitItem(
            id: "excess_alcohol",
            name: "Heavy Alcohol Drinks",
            category: .bloodVillains,
            nutrientTag: "Ethanol Toxicity",
            iconName: "wineglass.fill",
            unitLabel: "2 drinks",
            defaultStepAmount: 2,
            safeDailyLimit: 1,
            limitDescription: "Low-risk limit: ≤ 1 drink/day",
            physiologicalEffect: "Suppresses bone marrow erythropoiesis/megakaryocytes, dehydrates plasma, and disrupts hepatic glucose release.",
            rbcDeltaPerServing: -0.45,
            wbcDeltaPerServing: -1100,
            pltDeltaPerServing: -45000,
            glucoseDeltaPerServing: -14
        ),
        FoodHabitItem(
            id: "sedentary_hours",
            name: "Prolonged Sitting",
            category: .bloodVillains,
            nutrientTag: "Venous Stasis",
            iconName: "chair.lounge.fill",
            unitLabel: "4 hours sitting",
            defaultStepAmount: 4,
            safeDailyLimit: 4,
            limitDescription: "Break sitting every 30–60 min",
            physiologicalEffect: "Slows skeletal muscle glucose uptake (+Glucose), reduces venous return, and concentrates clotting factors (+PLT risk).",
            rbcDeltaPerServing: 0.12,
            wbcDeltaPerServing: 1100,
            pltDeltaPerServing: 42000,
            glucoseDeltaPerServing: 36
        )
    ]
}

// MARK: - Sugar & Sedentary Timeline
struct MetabolicTimelineMilestone: Identifiable {
    let id = UUID()
    let phaseTitle: String
    let timeframe: String
    let iconName: String
    let accentColor: Color
    let headline: String
    let mechanism: String
    let visualImpactSummary: String
    
    static let milestones: [MetabolicTimelineMilestone] = [
        MetabolicTimelineMilestone(
            phaseTitle: "Immediate Impact",
            timeframe: "15 – 60 Minutes",
            iconName: "timer",
            accentColor: .orange,
            headline: "Glycemic Surge & Plasma Drag",
            mechanism: "Refined sugars rapidly cross the intestinal wall, spiking blood glucose >160 mg/dL. Pancreatic beta-cells flood blood with insulin, followed by reactive brain fog and lethargy.",
            visualImpactSummary: "Glucose crystals appear in plasma; hyperosmolarity slightly slows red cell glide and triggers mild endothelial oxidative stress."
        ),
        MetabolicTimelineMilestone(
            phaseTitle: "Short-Term Adaptation",
            timeframe: "Days to Weeks",
            iconName: "calendar",
            accentColor: .yellow,
            headline: "Insulin Resistance & Low-Grade Inflammation",
            mechanism: "Paired with prolonged sitting, skeletal muscles downregulate GLUT4 glucose uptake. Adipose tissues and vessel walls release IL-6 cytokines, nudging WBC count upward.",
            visualImpactSummary: "Persistent glucose traffic, emerging leukocyte surveillance activation, and higher platelet collision rates."
        ),
        MetabolicTimelineMilestone(
            phaseTitle: "Long-Term Damage",
            timeframe: "Months to Years",
            iconName: "clock.badge.exclamationmark.fill",
            accentColor: .red,
            headline: "Type 2 Diabetes, High HbA1c & Thrombosis",
            mechanism: "Glucose permanently binds to hemoglobin (HbA1c >6.5%) and vessel collagen (AGEs). Chronic endothelial injury drives atherosclerosis, microvascular damage (eyes, kidneys, nerves), and arterial clots.",
            visualImpactSummary: "Darkened glycated endothelium, crowded glucose crystals, sluggish flow, and platelet-fibrin thrombus networks."
        )
    ]
}

// MARK: - Daily Tracker Entry
struct DailyIntakeEntry: Identifiable, Equatable {
    let item: FoodHabitItem
    var servings: Int
    
    var id: String { item.id }
    
    var totalQuantity: Double {
        Double(servings) * item.defaultStepAmount
    }
    
    var exceedsSafeLimit: Bool {
        if item.category == .bloodVillains {
            return totalQuantity > item.safeDailyLimit && servings > 0
        }
        return false
    }
}
