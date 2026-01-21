//
//  StatCard.swift
//  Fasting
//
//  Apple Health 风格的统计卡片
//

import SwiftUI

/// 统计卡片视图
struct StatCard: View {
    // MARK: - Properties
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 数值
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // 副标题（可选）
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 紧凑型统计卡片
struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 大号统计卡片（用于突出显示）
struct LargeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: String? = nil
    var trendUp: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标和标题
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 趋势指示（可选）
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(trend)
                            .font(.caption)
                    }
                    .foregroundStyle(trendUp ? .green : .red)
                }
            }
            
            // 大号数值
            Text(value)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [color.opacity(0.1), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    ScrollView {
        VStack(spacing: 16) {
            // 标准卡片
            StatCard(
                title: "连续天数",
                value: "7",
                icon: "flame.fill",
                color: .orange,
                subtitle: "最长记录: 21天"
            )
            
            // 紧凑卡片
            HStack(spacing: 12) {
                CompactStatCard(
                    title: "本周",
                    value: "5/7",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                CompactStatCard(
                    title: "平均",
                    value: "16.2h",
                    icon: "clock.fill",
                    color: .blue
                )
            }
            
            // 大号卡片
            LargeStatCard(
                title: "总断食时长",
                value: "288h",
                icon: "hourglass",
                color: .purple,
                trend: "+12%",
                trendUp: true
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
