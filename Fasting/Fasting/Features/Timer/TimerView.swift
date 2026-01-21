//
//  TimerView.swift
//  Fasting
//
//  断食计时器主界面
//

import SwiftUI
import SwiftData

struct TimerView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var fastingService = FastingService.shared
    @State private var showPresetSheet = false
    @State private var showConfirmEndSheet = false
    @State private var timer: Timer?
    @State private var currentTime = Date()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 状态指示器
                    statusIndicator
                    
                    // 进度环和计时器
                    timerSection
                    
                    // 操作按钮
                    actionSection
                    
                    // 快速统计
                    quickStatsSection
                }
                .padding()
            }
            .navigationTitle("断食")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                fastingService.configure(with: modelContext)
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .sheet(isPresented: $showPresetSheet) {
                PresetSelectionSheet { preset, customDuration in
                    startFasting(preset: preset, customDuration: customDuration)
                }
                .presentationDetents([.medium])
            }
            .confirmationDialog(
                "确认结束断食",
                isPresented: $showConfirmEndSheet,
                titleVisibility: .visible
            ) {
                Button("结束断食", role: .destructive) {
                    endFasting()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("已断食 \(formattedCurrentDuration)，确定要结束吗？")
            }
        }
    }
    
    // MARK: - Views
    
    /// 状态指示器
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(fastingService.isFasting ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
    
    /// 计时器区域
    private var timerSection: some View {
        ProgressRingWithContent(
            progress: fastingService.progress,
            lineWidth: 24,
            gradientColors: fastingService.isFasting ? [.green, .blue] : [.gray.opacity(0.5), .gray.opacity(0.3)]
        ) {
            VStack(spacing: 8) {
                // 主计时器
                Text(formattedCurrentDuration)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(fastingService.isFasting ? .primary : .secondary)
                
                // 方案名称
                if let preset = fastingService.currentFast?.presetType {
                    Text(preset.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 剩余时间（如果正在断食）
                if fastingService.isFasting && !fastingService.isGoalAchieved {
                    Text("剩余 \(formattedRemainingDuration)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // 目标达成提示
                if fastingService.isGoalAchieved {
                    Label("已达成目标！", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(height: 280)
        .padding(.vertical, 20)
    }
    
    /// 操作按钮区域
    private var actionSection: some View {
        VStack(spacing: 16) {
            if fastingService.isFasting {
                // 结束按钮
                PrimaryButton(
                    title: "结束断食",
                    action: { showConfirmEndSheet = true },
                    icon: "stop.fill",
                    isDestructive: true
                )
            } else {
                // 开始按钮
                PrimaryButton(
                    title: "开始断食",
                    action: { showPresetSheet = true },
                    icon: "play.fill"
                )
            }
        }
    }
    
    /// 快速统计区域
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速统计")
                .font(.headline)
            
            HStack(spacing: 12) {
                CompactStatCard(
                    title: "连续天数",
                    value: "7",  // TODO: 实际计算
                    icon: "flame.fill",
                    color: .orange
                )
                CompactStatCard(
                    title: "本周完成",
                    value: "5/7",  // TODO: 实际计算
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if fastingService.isFasting {
            return fastingService.isGoalAchieved ? "目标已达成" : "断食进行中"
        }
        return "未在断食"
    }
    
    private var formattedCurrentDuration: String {
        FastingRecord.formatDuration(fastingService.currentDuration)
    }
    
    private var formattedRemainingDuration: String {
        FastingRecord.formatShortDuration(fastingService.remainingDuration)
    }
    
    // MARK: - Actions
    
    private func startFasting(preset: FastingPreset, customDuration: TimeInterval?) {
        fastingService.startFasting(preset: preset, customDuration: customDuration)
        showPresetSheet = false
    }
    
    private func endFasting() {
        fastingService.endFasting()
        
        // 成功反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preset Selection Sheet

struct PresetSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (FastingPreset, TimeInterval?) -> Void
    
    @State private var selectedPreset: FastingPreset = .sixteen8
    @State private var customHours: Double = 16
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 预设选项
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(FastingPreset.allCases) { preset in
                        PresetCard(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        ) {
                            selectedPreset = preset
                        }
                    }
                }
                
                // 自定义时长滑块（当选择自定义时）
                if selectedPreset == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("断食时长: \(Int(customHours)) 小时")
                            .font(.headline)
                        
                        Slider(value: $customHours, in: 1...72, step: 1)
                            .tint(.accentColor)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
                
                // 开始按钮
                PrimaryButton(title: "开始断食", action: {
                    let customDuration = selectedPreset == .custom ? customHours * 3600 : nil
                    onSelect(selectedPreset, customDuration)
                }, icon: "play.fill")
            }
            .padding()
            .navigationTitle("选择断食方案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 预设卡片
struct PresetCard: View {
    let preset: FastingPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(preset.displayName)
                    .font(.headline)
                
                Text("\(preset.fastingHours)小时断食")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct SettingsView: View {
    var body: some View {
        List {
            Section("断食设置") {
                Text("默认方案")
                Text("通知设置")
            }
            
            Section("数据") {
                Text("Apple Health 同步")
                Text("iCloud 同步")
            }
            
            Section("关于") {
                Text("版本 1.0.0")
            }
        }
        .navigationTitle("设置")
    }
}

// MARK: - Preview

#Preview {
    TimerView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
