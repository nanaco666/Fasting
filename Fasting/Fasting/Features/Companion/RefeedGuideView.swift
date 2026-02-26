//
//  RefeedGuideView.swift
//  Fasting
//
//  断食结束后的科学复食指导
//

import SwiftUI

struct RefeedGuideView: View {
    @Environment(\.dismiss) private var dismiss
    let duration: TimeInterval
    let wasGoalMet: Bool
    
    private var fastingHours: Double { duration / 3600 }
    
    private var plan: RefeedPlan {
        RefeedGuide.plan(forHours: fastingHours)
    }
    
    private var completion: (title: String, body: String) {
        CompanionEngine.completionMessage(hours: fastingHours, isGoalAchieved: wasGoalMet)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Celebration header
                    celebrationHeader
                    
                    // Refeed steps
                    refeedSteps
                    
                    // Warnings
                    if !plan.warnings.isEmpty {
                        warningsSection
                    }
                }
                .padding(24)
            }
            .navigationTitle("Refeed Guide".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.General.done) { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Celebration
    
    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            Text(wasGoalMet ? "🎉" : "💪")
                .font(.system(size: 56))
            
            Text(completion.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text(completion.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Duration badge
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                Text(String(format: "%.1fh", fastingHours))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.fastingGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.fastingGreen.opacity(0.1), in: Capsule())
        }
    }
    
    // MARK: - Refeed Steps
    
    private var refeedSteps: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(plan.title)
                .font(.title3.bold())
            
            Text(plan.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                refeedStepRow(step: step, index: index)
            }
        }
    }
    
    private func refeedStepRow(step: RefeedStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: step.icon)
                        .font(.body)
                        .foregroundStyle(step.color)
                }
                
                if index < plan.steps.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 2, height: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(step.timing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(step.color)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(step.title)
                    .font(.body.weight(.semibold))
                
                Text(step.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Warnings
    
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Important".localized, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            ForEach(plan.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }
}
