import SwiftUI

// MARK: - Condition Severity
enum ConditionSeverity: String, Equatable {
    case optimal = "Optimal"
    case warning = "Clinical Warning"
    case critical = "Critical Alert"
    
    var color: Color {
        switch self {
        case .optimal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .optimal:
            return "checkmark.shield.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "cross.circle.fill"
        }
    }
}

// MARK: - Symptom Systems
enum SymptomSystem: String, CaseIterable, Identifiable {
    case neurological = "Neurological"
    case cardiorespiratory = "Cardiorespiratory"
    case cutaneousVascular = "Cutaneous & Vascular"
    case systemic = "Systemic & Metabolic"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .neurological: return "brain.head.profile"
        case .cardiorespiratory: return "lungs.fill"
        case .cutaneousVascular: return "hand.raised.fill"
        case .systemic: return "figure.stand"
        }
    }
    
    var color: Color {
        switch self {
        case .neurological: return .purple
        case .cardiorespiratory: return .red
        case .cutaneousVascular: return .orange
        case .systemic: return .cyan
        }
    }
}

struct SystemSymptomGroup: Identifiable, Equatable {
    let system: SymptomSystem
    let symptoms: [String]
    
    var id: String { system.rawValue }
}

// MARK: - Target 3D Human Organs (Macro View)
enum TargetOrgan: String, CaseIterable, Identifiable {
    case brain = "Brain"
    case lungs = "Lungs"
    case heart = "Heart"
    case liverSpleen = "Liver & Spleen"
    case boneMarrow = "Bone Marrow"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .brain: return "brain.head.profile"
        case .lungs: return "lungs.fill"
        case .heart: return "heart.fill"
        case .liverSpleen: return "cross.vial.fill"
        case .boneMarrow: return "figure.walk"
        }
    }
    
    var physiologicalRole: String {
        switch self {
        case .brain:
            return "Consumes 20% of total oxygen and glucose; highly sensitive to hypoxia, hypoglycemia, and microthrombi."
        case .lungs:
            return "Site of alveolar gas exchange loading O2 onto erythrocyte hemoglobin and clearing CO2."
        case .heart:
            return "Muscular pump adjusting stroke rate and output according to blood oxygen delivery and fluid viscosity."
        case .liverSpleen:
            return "Filters senescent red cells, stores iron/platelets, regulates blood glucose glycogen, and clears pathogens."
        case .boneMarrow:
            return "Hematopoietic factory in the femur and sternum producing erythrocytes, leukocytes, and megakaryocytes."
        }
    }
    
    func impactDescription(for condition: ClinicalCondition, rbc: Double, wbc: Double, plt: Double, glucose: Double) -> String {
        switch self {
        case .brain:
            switch condition {
            case .homeostasis:
                return "Optimal cerebral perfusion with balanced oxygen (RBC \(BloodCellType.erythrocytes.formattedValue(rbc))) and steady glucose fuel (\(Int(glucose)) mg/dL)."
            case .anemia, .pancytopenia:
                return "Cerebral hypoxia warning: low hemoglobin oxygen delivery triggers dizziness, cognitive fog, and compensatory vasodilation."
            case .hypoglycemia:
                return "Acute Neuroglycopenia! Neurons lack immediate glucose (\(Int(glucose)) mg/dL), risking confusion, tremors, and syncope."
            case .hyperglycemia:
                return "Hyperosmolar stress and microvascular glycation accelerate diabetic neuropathy and blood-brain barrier inflammation."
            case .thrombosisRisk:
                return "High risk of ischemic stroke or transient ischemic attack (TIA) from platelet-fibrin emboli."
            case .polycythemia:
                return "Sluggish cerebral venous flow causes throbbing headaches, visual blurring, and tinnitus."
            default:
                return "Mild metabolic strain; monitor hydration, oxygenation, and inflammatory markers."
            }
            
        case .lungs:
            switch condition {
            case .homeostasis:
                return "Efficient alveolar-capillary oxygen saturation with smooth laminar pulmonary flow."
            case .anemia, .pancytopenia:
                return "Dyspnea and tachypnea: lungs hyperventilate to maximize oxygen uptake across depleted red blood cells."
            case .thrombosisRisk:
                return "Pulmonary Embolism (PE) alert! Hypercoagulable clots can lodge in pulmonary arterioles."
            case .infectionResponse:
                return "Elevated cytokine circulation increases alveolar capillary permeability and respiratory rate."
            case .polycythemia:
                return "Pulmonary hypertension strain due to thick, hyperviscous blood passing through fine alveolar capillaries."
            default:
                return "Pulmonary gas exchange remains intact under current hematological parameters."
            }
            
        case .heart:
            switch condition {
            case .homeostasis:
                return "Steady resting rhythm (~72 BPM) pumping low-resistance blood smoothly through coronary arteries."
            case .anemia, .pancytopenia:
                return "Compensatory tachycardia! The heart beats rapidly to circulate sparse erythrocytes faster and preserve tissue oxygen."
            case .polycythemia:
                return "Severe cardiac afterload! Viscous blood forces heavy ventricular contraction, raising blood pressure and hypertrophy risk."
            case .hyperglycemia:
                return "Endothelial glycation accelerates coronary atherosclerosis and stiffens myocardial microvessels."
            case .thrombosisRisk:
                return "Coronary thrombosis danger: sticky platelet aggregates threaten acute myocardial ischemia."
            case .infectionResponse:
                return "Inflammatory hyperdynamic state elevates heart rate and myocardial oxygen demand."
            default:
                return "Myocardium adapts workload to current plasma osmolarity and cellular volume."
            }
            
        case .liverSpleen:
            switch condition {
            case .homeostasis:
                return "Balanced splenic blood filtration and hepatic glycogen storage keeping fasting glucose at \(Int(glucose)) mg/dL."
            case .infectionResponse:
                return "Splenic immune activation: white pulp macrophages filter opsonized pathogens and amplify antibody production."
            case .hyperglycemia:
                return "Hepatic insulin resistance prevents glycogen suppression, worsening systemic glycemia and fatty liver steatosis."
            case .hypoglycemia:
                return "Hepatic glycogen reserves are depleted or blocked from releasing glucose into the bloodstream."
            case .thrombocytopenia, .pancytopenia:
                return "Altered splenic sequestration or portal congestion contributes to dangerously low circulating platelets."
            case .polycythemia:
                return "Hepatosplenomegaly congestion from clearing excessive red blood cell turnover."
            default:
                return "Reticuloendothelial filtration continues monitoring circulating blood elements."
            }
            
        case .boneMarrow:
            switch condition {
            case .homeostasis:
                return "Steady hematopoietic stem cell turnover replenishing RBCs, WBCs, and platelets at physiological rates."
            case .infectionResponse:
                return "Hyperactive marrow! IL-1 and G-CSF signals surge granulopoiesis, pushing \(BloodCellType.leukocytes.formattedValue(wbc)) WBC/µL into circulation."
            case .pancytopenia:
                return "Critical Marrow Suppression! Simultaneous drop in RBC, WBC, and PLT indicates aplastic failure or severe toxicity."
            case .anemia:
                return "Renal erythropoietin (EPO) stimulates erythroid precursors to ramp up reticulocyte production."
            case .leukopenia:
                return "Suppressed myelopoiesis leaves peripheral white cell reserves critically depleted."
            case .thrombosisRisk:
                return "Excessive megakaryocyte proliferation floods the blood with hyper-reactive platelets."
            default:
                return "Marrow stem cell niches respond to systemic erythropoietin and cytokine feedback."
            }
        }
    }
}

// MARK: - Clinical Condition
enum ClinicalCondition: String, CaseIterable, Identifiable, Equatable {
    case homeostasis = "Physiological Homeostasis"
    case anemia = "Anemia (Erythropenia)"
    case polycythemia = "Polycythemia (Erythrocytosis)"
    case leukopenia = "Leukopenia (Immunosuppression)"
    case infectionResponse = "Leukocytosis (Active Infection)"
    case thrombocytopenia = "Thrombocytopenia (Bleeding Risk)"
    case thrombosisRisk = "Thrombocytosis (Clotting Risk)"
    case hyperglycemia = "Hyperglycemia (Diabetes Risk)"
    case hypoglycemia = "Hypoglycemia (Neuroglycopenia)"
    case pancytopenia = "Pancytopenia (Marrow Failure)"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var medicalTerm: String {
        switch self {
        case .homeostasis: return "Euvolemic & Glycemic Homeostasis"
        case .anemia: return "Erythropenia / Tissue Hypoxia"
        case .polycythemia: return "Hyperviscosity Syndrome"
        case .leukopenia: return "Immunodeficiency / Neutropenia"
        case .infectionResponse: return "Reactive Leukocytosis"
        case .thrombocytopenia: return "Platelet Deficit / Hemorrhagic Diathesis"
        case .thrombosisRisk: return "Intravascular Hypercoagulability"
        case .hyperglycemia: return "Pre-Diabetes / Type 2 Diabetes Risk"
        case .hypoglycemia: return "Acute Neuroglycopenia"
        case .pancytopenia: return "Tri-Lineage Hematopoietic Failure"
        }
    }
    
    var severity: ConditionSeverity {
        switch self {
        case .homeostasis:
            return .optimal
        case .anemia, .leukopenia, .thrombocytopenia, .hyperglycemia:
            return .warning
        case .polycythemia, .infectionResponse, .thrombosisRisk, .hypoglycemia, .pancytopenia:
            return .critical
        }
    }
    
    var severityColor: Color {
        severity.color
    }
    
    var statusIcon: String {
        switch self {
        case .homeostasis: return "checkmark.seal.fill"
        case .anemia: return "lungs.fill"
        case .polycythemia: return "gauge.with.dots.needle.67percent"
        case .leukopenia: return "exclamationmark.shield.fill"
        case .infectionResponse: return "microbe.fill"
        case .thrombocytopenia: return "drop.triangle.fill"
        case .thrombosisRisk: return "waveform.path.ecg.rectangle.fill"
        case .hyperglycemia: return "cube.transparent.fill"
        case .hypoglycemia: return "bolt.trianglebadge.exclamationmark.fill"
        case .pancytopenia: return "exclamationmark.octagon.fill"
        }
    }
    
    var badgeTitle: String {
        switch self {
        case .homeostasis: return "OPTIMAL"
        case .anemia, .leukopenia, .thrombocytopenia, .hyperglycemia: return "WARNING"
        case .polycythemia, .infectionResponse, .thrombosisRisk, .hypoglycemia, .pancytopenia: return "CRITICAL ALERT"
        }
    }
    
    var laypersonExplanation: String {
        switch self {
        case .homeostasis:
            return "All blood cells and glucose levels are in dynamic harmony! Red cells deliver abundant oxygen, immune cells stand peacefully on patrol, platelets stay unactivated, and fuel is steady."
        case .anemia:
            return "Too few red blood cells are available to carry oxygen. Notice the paler bloodstream—muscles and brain starve for oxygen while the heart beats faster to compensate."
        case .polycythemia:
            return "Excessive red blood cells turn plasma into thick, sluggish traffic. Look at the slowed flow forcing the heart to work under dangerously high resistance."
        case .leukopenia:
            return "White blood cell defenses are critically low. Without enough immune sentries patrolling the vessel walls, minor pathogens can cause severe infections."
        case .infectionResponse:
            return "Immune defense on high alert! Bone marrow deployed an army of white blood cells emitting chemical cytokine signals to neutralize invading bacteria or viruses."
        case .thrombocytopenia:
            return "Platelet levels are too low to patch microscopic blood vessel leaks. Even slight bumps can lead to prolonged bleeding, bruising, and petechiae."
        case .thrombosisRisk:
            return "Excessive platelets are colliding and weaving sticky fibrin webs inside the vessel, sharply raising the danger of heart attack, pulmonary embolism, or stroke."
        case .hyperglycemia:
            return "Excess sugar crystals flood the plasma! High blood glucose slows circulation, causes oxidative stress that darkens vessel walls, and glycates hemoglobin (raising HbA1c)."
        case .hypoglycemia:
            return "Dangerous blood sugar drop! Brain neurons rely continuously on blood glucose for fuel—starving them triggers tremors, cold sweats, and rapid confusion."
        case .pancytopenia:
            return "Medical emergency: all three blood cell lines (RBC, WBC, and Platelets) dropped simultaneously, causing combined hypoxia, severe infection vulnerability, and bleeding risk."
        }
    }
    
    var biomedicalNote: String {
        switch self {
        case .homeostasis:
            return "Normal hematocrit (~40–45%), normoglycemia (70–99 mg/dL), normal leukocyte and platelet pools. Poiseuille laminar flow and endothelial nitric oxide signaling are preserved."
        case .anemia:
            return "Reduced hemoglobin depresses arterial oxygen content (CaO2 = 1.34 × Hb × SaO2), triggering carotid chemoreceptor-mediated sympathetic tachycardia."
        case .polycythemia:
            return "Hematocrit >55% causes an exponential surge in whole blood viscosity, impairing capillary microcirculation and increasing thromboembolic risk."
        case .leukopenia:
            return "Absolute neutrophil count depression impairs innate phagocytosis and oxidative burst, weakening mucosal immunity."
        case .infectionResponse:
            return "IL-1, TNF-alpha, and G-CSF mobilize marrow neutrophils, inducing endothelial rolling, diapedesis, and cytokine particle signaling."
        case .thrombocytopenia:
            return "Defective primary hemostasis due to insufficient platelet adhesion to subendothelial collagen via von Willebrand Factor (vWF)."
        case .thrombosisRisk:
            return "Shear-induced platelet activation (SIPA) accelerates ADP/TXA2 release, thrombin generation, and insoluble cross-linked fibrin mesh formation."
        case .hyperglycemia:
            return "Sustained plasma glucose >140 mg/dL drives non-enzymatic glycation (HbA1c & AGEs), protein kinase C activation, reactive oxygen species (ROS), and endothelial nitric oxide depletion."
        case .hypoglycemia:
            return "Glucose <65 mg/dL triggers autonomic counter-regulatory epinephrine/glucagon surge alongside acute cerebral ATP depletion (neuroglycopenia)."
        case .pancytopenia:
            return "Tri-lineage cytopenia stemming from bone marrow aplasia, infiltrative disease, cytotoxic exposure, or severe B12/folate depletion."
        }
    }
    
    var cardiovascularImpact: String {
        switch self {
        case .homeostasis:
            return "Balanced cardiac output (~5 L/min) and healthy vascular compliance."
        case .anemia:
            return "High-output cardiac strain with compensatory tachycardia (>100 BPM)."
        case .polycythemia:
            return "High systemic vascular resistance, hypertension, and left ventricular overload."
        case .leukopenia:
            return "Risk of septic shock and distributive vasodilation if bacteremia develops."
        case .infectionResponse:
            return "Hyperdynamic inflammatory pulse (~95 BPM) and increased capillary permeability."
        case .thrombocytopenia:
            return "Risk of hypovolemic shock during internal or mucocutaneous hemorrhage."
        case .thrombosisRisk:
            return "Imminent arterial/venous occlusion risk (MI, PE, DVT, or ischemic stroke)."
        case .hyperglycemia:
            return "Microvascular endothelial stiffening, osmotic fluid shifts, and accelerated atherosclerosis."
        case .hypoglycemia:
            return "Adrenergic palpitations, systolic hypertension spike, and arrhythmia risk."
        case .pancytopenia:
            return "Severe high-output cardiac decompensation paired with hemorrhagic shock risk."
        }
    }
    
    var visual3DClues: [String] {
        switch self {
        case .homeostasis:
            return [
                "Vibrant ruby-red biconcave erythrocytes",
                "Smooth laminar flow velocity",
                "Clean plasma with zero glucose crystal excess",
                "Calm green/blue baseline organs in Macro View"
            ]
        case .anemia:
            return [
                "Sparse red cell population",
                "Pale pink, low-oxygenation lumen",
                "Brain & Lungs flashing hypoxia alert in 3D Body"
            ]
        case .polycythemia:
            return [
                "Overcrowded red cell traffic",
                "Sluggish viscous flow rate",
                "Strained dark crimson Heart in 3D Body"
            ]
        case .leukopenia:
            return [
                "Marked absence of rolling white sentries",
                "Dimmed Bone Marrow indicator in 3D Body"
            ]
        case .infectionResponse:
            return [
                "Surge of textured white leukocytes",
                "Soft glowing cyan cytokine aura particles",
                "Glowing active Bone Marrow & Spleen in 3D Body"
            ]
        case .thrombocytopenia:
            return [
                "Depleted golden biconvex platelet fragments",
                "Spleen & vascular warning pulse in 3D Body"
            ]
        case .thrombosisRisk:
            return [
                "Clustered golden platelets",
                "Oriented fibrin thread networks bridging aggregates",
                "Heart, Lungs & Brain clotting alerts in 3D Body"
            ]
        case .hyperglycemia:
            return [
                "Translucent white glucose crystals floating in plasma",
                "Darkened endothelial vessel wall (glycation stress)",
                "Hyperosmolar drag slowing blood velocity"
            ]
        case .hypoglycemia:
            return [
                "Complete absence of plasma glucose energy reserves",
                "Urgent flashing Brain warning in 3D Body",
                "Adrenergic rapid heart pulsation"
            ]
        case .pancytopenia:
            return [
                "Simultaneous scarcity of RBCs, WBCs, and Platelets",
                "Pale lumen and critical Bone Marrow suppression alert",
                "Multi-organ hypoxia & vascular alerts in 3D Body"
            ]
        }
    }
    
    /// Categorized real-world clinical symptoms grouped by physiological system
    var symptomsBySystem: [SystemSymptomGroup] {
        switch self {
        case .homeostasis:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Clear mental focus", "Stable mood & restorative sleep"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Steady resting pulse (60–80 BPM)", "Effortless breathing on exertion"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Warm extremities", "Prompt capillary refill & normal healing"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Sustained daily energy", "Balanced post-meal stamina"])
            ]
        case .anemia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Dizziness & lightheadedness", "Difficulty concentrating (brain fog)", "Pulsatile headaches"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Shortness of breath on stairs", "Heart palpitations (tachycardia)", "Exercise intolerance"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Pale skin & inner eyelids (conjunctival pallor)", "Cold hands & feet", "Brittle nails"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Persistent muscle fatigue", "General weakness"])
            ]
        case .polycythemia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Throbbing headaches", "Visual disturbances / blurred vision", "Tinnitus (ringing in ears)"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Elevated blood pressure", "Chest tightness under strain"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Ruddy/flushed complexion (plethora)", "Intense itching after warm showers (aquagenic pruritus)"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Joint pain (gout risk)", "Abdominal fullness (splenomegaly)"])
            ]
        case .leukopenia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Lethargy during subclinical infections", "Malaise"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Frequent cough or sinusitis", "Vulnerability to pneumonia"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Recurrent mouth ulcers & sore throat", "Slow-healing skin abscesses"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Unexplained fevers & chills", "Night sweats"])
            ]
        case .infectionResponse:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Fever-induced headache", "Body aches & lethargy"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Rapid breathing (tachypnea)", "Elevated resting heart rate"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Localized warmth, redness & swelling", "Flushed skin from vasodilation"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["High fever & rigors", "Swollen lymph nodes", "Loss of appetite"])
            ]
        case .thrombocytopenia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Severe headache (alert for intracranial bleed)"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Orthostatic dizziness if blood volume drops"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Pinpoint red/purple spots (petechiae)", "Easy bruising (ecchymosis)", "Bleeding gums & nosebleeds"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Prolonged bleeding from minor cuts", "Heavy menstrual flow"])
            ]
        case .thrombosisRisk:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Transient numbness or visual spots (TIA risk)", "Headache"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Sudden chest pain or shortness of breath (PE alert)"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Unilateral calf swelling, warmth & pain (DVT)", "Burning sensation in fingers/toes (erythromelalgia)"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Elevated clotting risk during immobility"])
            ]
        case .hyperglycemia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Blurry vision (osmotic lens swelling)", "Post-meal brain fog & drowsiness", "Tingling in feet (neuropathy)"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Elevated resting pulse", "Endothelial arterial stiffening"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Dry skin & slow wound healing", "Darkened neck/skin folds (acanthosis nigricans)"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Excessive thirst (polydipsia)", "Frequent urination (polyuria)", "Energy crashes"])
            ]
        case .hypoglycemia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Sudden confusion & irritability", "Trembling / shakiness", "Slurred speech & dizziness"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Pounding rapid heart rate (adrenergic surge)"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Profuse cold sweating (diaphoresis)", "Pale clammy skin"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["Intense sudden hunger", "Weakness & syncope risk"])
            ]
        case .pancytopenia:
            return [
                SystemSymptomGroup(system: .neurological, symptoms: ["Severe dizziness, syncope risk & fatigue"]),
                SystemSymptomGroup(system: .cardiorespiratory, symptoms: ["Dyspnea at rest & severe tachycardia"]),
                SystemSymptomGroup(system: .cutaneousVascular, symptoms: ["Extreme pallor + petechiae + spontaneous gum bleeding"]),
                SystemSymptomGroup(system: .systemic, symptoms: ["High fever from opportunistic infections", "Profound systemic weakness"])
            ]
        }
    }
    
    var primaryOrganAtRisk: String {
        switch self {
        case .homeostasis: return "Whole Body (Optimal)"
        case .anemia: return "Brain & Heart (Hypoxia)"
        case .polycythemia: return "Heart & Brain (Hyperviscosity)"
        case .leukopenia: return "Bone Marrow & Mucosa"
        case .infectionResponse: return "Bone Marrow & Spleen"
        case .thrombocytopenia: return "Spleen & Microcirculation"
        case .thrombosisRisk: return "Heart, Lungs & Brain"
        case .hyperglycemia: return "Blood Vessels, Brain & Kidneys"
        case .hypoglycemia: return "Brain (Neuroglycopenia)"
        case .pancytopenia: return "Bone Marrow (All Systems)"
        }
    }
    
    var clinicalAction: String {
        switch self {
        case .homeostasis:
            return "Maintain whole-food nutrition, regular aerobic exercise, and hydration."
        case .anemia:
            return "Evaluate ferritin, iron intake paired with Vitamin C, and B12/folate levels."
        case .polycythemia:
            return "Evaluate hydration, JAK2 status, or perform therapeutic phlebotomy."
        case .leukopenia:
            return "Implement infection precautions and investigate marrow or medication causes."
        case .infectionResponse:
            return "Identify infectious focus, obtain cultures, and initiate targeted therapy."
        case .thrombocytopenia:
            return "Avoid NSAIDs/trauma; monitor platelet recovery and screen for ITP or viral causes."
        case .thrombosisRisk:
            return "Hydrate immediately, avoid prolonged sitting, and evaluate antiplatelet therapy."
        case .hyperglycemia:
            return "Cut refined sugars, activate muscle GLUT4 glucose uptake via brisk walking, and test HbA1c."
        case .hypoglycemia:
            return "Administer 15g fast-acting carbohydrates immediately and recheck glucose in 15 minutes."
        case .pancytopenia:
            return "Urgent hematology evaluation and bone marrow biopsy; monitor bleeding and fever."
        }
    }
}
