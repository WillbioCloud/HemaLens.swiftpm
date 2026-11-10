# Software Design Document (SDD) — HemaLens

## 1. Visão Geral do Sistema
**Nome do Projeto:** HemaLens (Descomplicador de Hemograma)  
**Plataforma Alvo:** iPadOS 17+ / macOS 14+ (Formato `.swiftpm` — Swift Playgrounds App Package)  
**Objetivo:** Aplicativo educacional interativo de até 3 minutos para o Apple Swift Student Challenge. Traduz parâmetros clínicos de um hemograma (Série Vermelha, Série Branca e Plaquetas) em uma simulação 3D interativa em tempo real dentro de um vaso sanguíneo, promovendo alfabetização em saúde.

### Restrições Rígidas (Requisitos da Apple)
1. **Formato:** Pacote `.swiftpm` autocontido com `Package.swift` na raiz.
2. **Tamanho Máximo:** `< 25 MB` em formato `.zip` (Zero dependência de pacotes externos; 3D 100% procedural via código).
3. **Execução:** 100% Offline (Sem chamadas de rede/API).
4. **Idioma da Interface:** Inglês (requisito de avaliação global da Apple), mantendo rigor científico biomédico.

---

## 2. Arquitetura de Diretórios (.swiftpm)
O Antigravity deve criar e manter estritamente esta árvore de arquivos:

```text
HemaLens.swiftpm/
├── Package.swift
├── SDD.md
└── Sources/
    ├── App/
    │   └── HemaLensApp.swift          # @main Entry Point
    ├── Models/
    │   ├── BloodParameter.swift       # Structs de dados laboratoriais e valores de referência
    │   └── ClinicalCondition.swift    # Enum de diagnósticos (Normal, Anemia, Leucocitose, etc.)
    ├── ViewModels/
    │   └── LabViewModel.swift         # Estado reativo (@Observable / ObservableObject)
    ├── Views/
    │   ├── MainLabView.swift          # Layout principal (Split View: 3D + Painel de Controle)
    │   ├── OnboardingModalView.swift  # Introdução rápida (contexto biomédico de 30s)
    │   ├── ControlPanelView.swift     # Sliders interativos e presets clínicos
    │   └── DiagnosticCardView.swift   # Card dinâmico explicando a fisiologia atual
    └── Scene3D/
        ├── BloodVesselSceneView.swift # UIViewRepresentable / NSViewRepresentable bridge
        └── VesselSceneController.swift# Motor procedural SceneKit (Células, Fluxo e Iluminação)
3. Paralelo de Arquitetura (React vs. SwiftUI)Para manter a consistência na manutenção do código:useState (React) $\rightarrow$ @State / @Published (SwiftUI): Controla os valores dos sliders em tempo real.useContext / Zustand $\rightarrow$ @StateObject / @EnvironmentObject (LabViewModel): Estado global que alimenta tanto a UI em SwiftUI quanto a cena 3D no SceneKit.Three.js Canvas $\rightarrow$ SCNView (UIViewRepresentable): Componente que encapsula a árvore 3D (SCNScene) e reage às mudanças de estado do ViewModel no método updateUIView.4. Especificação de Dados e Regras Biomédicas (Models)4.1 Parâmetros Manipuláveis (Sliders)Erythrocytes (Hemácias / RBC):Range no Slider: 2.0 a 7.0 milhões/µL (Referência Normal: 4.5 - 5.9).Impacto Visual 3D: Quantidade de discos bicôncavos vermelhos, velocidade do fluxo (viscosidade) e saturação da iluminação ambiente (oxigenação).Leukocytes (Leucócitos / WBC):Range no Slider: 1.000 a 25.000 /µL (Referência Normal: 4.500 - 11.000).Impacto Visual 3D: Quantidade de esferas brancas texturizadas maiores. Acima de 11.000, ativa partículas de anticorpos/citocinas e movimentação de patrulha.Platelets (Plaquetas / PLT):Range no Slider: 50.000 a 600.000 /µL (Referência Normal: 150.000 - 450.000).Impacto Visual 3D: Pequenos fragmentos celulares dourados/amarelados. Acima de 450.000, começam a se agrupar formando redes de fibrina (risco de trombo).4.2 Lógica de Diagnóstico Automático (ClinicalCondition)O LabViewModel avalia os 3 parâmetros combinados e retorna o estado prioritário:anemia (RBC < 4.0): Alerta de baixa oxigenação tecidual, fadiga celular, fluxo lento e pálido.polycythemia (RBC > 6.0): Sangue hiperviscoso, fluxo arrastado, sobrecarga cardíaca.leukopenia (WBC < 4.000): Imunossupressão; alerta de vulnerabilidade a patógenos.infectionResponse (WBC > 12.000): Leucocitose ativa; resposta inflamatória aguda em andamento.thrombocytopenia (PLT < 140.000): Risco hemorrágico; falha na coagulação primária.thrombosisRisk (PLT > 450.000): Hipercoagulabilidade; agregação plaquetária visível no vaso.homeostasis (Todos dentro do range normal): Equilíbrio fisiológico perfeito.5. Motor Gráfico 3D Procedural (SceneKit — Zero Assets Externos)Para garantir que o projeto pese menos de 1 MB e rode a 60 FPS no iPad:Vaso Sanguíneo (Endotélio): Um cilindro oco ou túnel curvo com material translúcido avermelhado (SCNMaterial.LightingModel.physicallyBased), iluminado por luzes pontuais internas.Geometria das Células (Instanciadas via Código):Hemácias: SCNSphere achatada no eixo Y (scale = SCNVector3(1.0, 0.35, 1.0)) com shader avermelhado fosco para simular o formato bicôncavo.Leucócitos: SCNSphere com raio maior, cor branco-azulada levemente emissiva para destacar no fluxo.Plaquetas: SCNBox ou SCodePyramid minúsculos com cantos arredondados (chamferRadius) girando no eixo.Animação de Fluxo Contínuo: SCNAction.moveBy(x:y:z:duration:) em loop infinito com reposicionamento (Object Pooling) quando a célula ultrapassa o limite da câmera, evitando recriação de nós na memória.6. Fluxo da Experiência de 3 Minutos (Guiado para o Juiz)Minuto 0:00 - 0:30 (Onboarding): Modal em Glassmorphism apresentando a missão: "Exams are full of cryptic numbers. Let's look inside the vein to see what they actually mean."Minuto 0:30 - 2:00 (Sandbox + Casos Clínicos):O usuário pode arrastar os 3 sliders livremente OU clicar em 3 botões de Patient Cases pré-configurados:Case 1: Iron Deficiency AnemiaCase 2: Acute Bacterial InfectionCase 3: Coagulation DisorderMinuto 2:00 - 3:00 (Quiz Rápido / "Restore Homeostasis"): Um botão desafia o avaliador a estabilizar um paciente crítico ajustando os sliders até atingir a faixa verde de Homeostase, exibindo uma tela final de conclusão com impacto social.7. Diretrizes de Código para a IA (Antigravity Rules)Usar compatibilidade iOS 17+ (ObservableObject com @Published ou macro @Observable).Nunca importar bibliotecas de terceiros no Package.swift.Separar estritamente a lógica matemática/biomédica (LabViewModel) da camada de renderização (VesselSceneController).Todo o estilo visual do SwiftUI deve usar ultraThinMaterial (efeito vidro nativo da Apple), cantos arredondados (clipShape(RoundedRectangle(cornerRadius: 20))) e ícones nativos do SF Symbols (ex: drop.fill, shield.lefthalf.filled, waveform.path.ecg).