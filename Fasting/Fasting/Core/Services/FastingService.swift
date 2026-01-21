//
//  FastingService.swift
//  Fasting
//
//  断食服务 - 管理断食状态和操作
//

import Foundation
import SwiftData
import Observation

/// 断食服务
@Observable
final class FastingService {
    // MARK: - Properties
    
    /// 当前正在进行的断食记录
    private(set) var currentFast: FastingRecord?
    
    /// 是否正在断食
    var isFasting: Bool {
        currentFast != nil && currentFast?.status == .inProgress
    }
    
    /// 当前断食进度 (0.0 - 1.0)
    var progress: Double {
        currentFast?.progress ?? 0
    }
    
    /// 当前已断食时长
    var currentDuration: TimeInterval {
        currentFast?.currentDuration ?? 0
    }
    
    /// 目标断食时长
    var targetDuration: TimeInterval {
        currentFast?.targetDuration ?? 0
    }
    
    /// 剩余断食时间
    var remainingDuration: TimeInterval {
        max(targetDuration - currentDuration, 0)
    }
    
    /// 是否已达成目标
    var isGoalAchieved: Bool {
        currentDuration >= targetDuration
    }
    
    // MARK: - Private
    
    private var modelContext: ModelContext?
    
    // MARK: - Initializer
    
    init() {}
    
    // MARK: - Setup
    
    /// 配置 ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentFast()
    }
    
    // MARK: - Public Methods
    
    /// 开始新的断食
    @discardableResult
    func startFasting(
        preset: FastingPreset,
        customDuration: TimeInterval? = nil
    ) -> FastingRecord {
        // 如果有正在进行的断食，先结束它
        if let current = currentFast, current.status == .inProgress {
            current.cancel()
        }
        
        // 确定断食时长
        let duration: TimeInterval
        if preset == .custom, let custom = customDuration {
            duration = custom
        } else {
            duration = TimeInterval(preset.fastingHours * 3600)
        }
        
        // 创建新记录
        let record = FastingRecord(
            startTime: Date(),
            targetDuration: duration,
            presetType: preset
        )
        
        // 保存到数据库
        modelContext?.insert(record)
        try? modelContext?.save()
        
        // 更新当前断食
        currentFast = record
        
        // 持久化当前断食 ID（防止应用被杀）
        saveCurrentFastId(record.id)
        
        return record
    }
    
    /// 结束当前断食
    func endFasting() {
        guard let current = currentFast else { return }
        
        current.complete()
        try? modelContext?.save()
        
        // 清除当前断食
        currentFast = nil
        clearCurrentFastId()
    }
    
    /// 取消当前断食
    func cancelFasting() {
        guard let current = currentFast else { return }
        
        current.cancel()
        try? modelContext?.save()
        
        // 清除当前断食
        currentFast = nil
        clearCurrentFastId()
    }
    
    /// 刷新当前断食状态（用于从后台恢复）
    func refresh() {
        loadCurrentFast()
    }
    
    // MARK: - Private Methods
    
    /// 加载当前正在进行的断食
    private func loadCurrentFast() {
        guard let modelContext = modelContext else { return }
        
        // 优先从 UserDefaults 获取保存的 ID
        if let savedId = loadCurrentFastId() {
            let descriptor = FetchDescriptor<FastingRecord>(
                predicate: #Predicate { $0.id == savedId }
            )
            if let record = try? modelContext.fetch(descriptor).first,
               record.status == .inProgress {
                currentFast = record
                return
            }
        }
        
        // 否则查找最近的进行中记录
        let descriptor = FetchDescriptor<FastingRecord>(
            predicate: #Predicate { $0.statusRaw == "in_progress" },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        if let record = try? modelContext.fetch(descriptor).first {
            currentFast = record
            saveCurrentFastId(record.id)
        }
    }
    
    // MARK: - UserDefaults Persistence
    
    private let currentFastIdKey = "com.fasting.currentFastId"
    
    private func saveCurrentFastId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentFastIdKey)
    }
    
    private func loadCurrentFastId() -> UUID? {
        guard let string = UserDefaults.standard.string(forKey: currentFastIdKey) else {
            return nil
        }
        return UUID(uuidString: string)
    }
    
    private func clearCurrentFastId() {
        UserDefaults.standard.removeObject(forKey: currentFastIdKey)
    }
}

// MARK: - Singleton

extension FastingService {
    /// 共享实例
    static let shared = FastingService()
}
