import SwiftUI
import Charts

struct ProgressStatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTimeframe: Timeframe = .month
    @State private var selectedMetric: Metric = .volume
    
    private enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    enum Metric: String, CaseIterable {
        case volume = "Volume"
        case sets = "Sets"
        case workouts = "Workouts"
    }
    
    private var filteredWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .week:
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            return dataManager.workouts.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return dataManager.workouts.filter { $0.date >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return dataManager.workouts.filter { $0.date >= yearAgo }
        }
    }
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let groupedWorkouts = Dictionary(grouping: filteredWorkouts) { workout in
            switch selectedTimeframe {
            case .week:
                return calendar.component(.weekday, from: workout.date)
            case .month:
                return calendar.component(.day, from: workout.date)
            case .year:
                return calendar.component(.month, from: workout.date)
            }
        }
        
        return groupedWorkouts.map { (key, workouts) in
            let value: Double
            switch selectedMetric {
            case .volume:
                value = workouts.flatMap { $0.exercises.flatMap { $0.sets } }
                    .compactMap { set in
                        guard let weight = set.weight, let reps = set.reps else { return nil }
                        return weight * Double(reps)
                    }
                    .reduce(0, +)
            case .sets:
                value = Double(workouts.flatMap { $0.exercises.flatMap { $0.sets } }.count)
            case .workouts:
                value = Double(workouts.count)
            }
            
            return ChartDataPoint(period: key, value: value)
        }.sorted { $0.period < $1.period }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Timeframe and Metric Selection
                    VStack(spacing: 16) {
                        // Timeframe Picker
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Metric Picker
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(Metric.allCases, id: \.self) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    
                    // Summary Cards
                    SummaryCardsView(workouts: filteredWorkouts, metric: selectedMetric)
                    
                    // Progress Chart
                    if !chartData.isEmpty {
                        ProgressChartView(data: chartData, metric: selectedMetric)
                    } else {
                        EmptyProgressView()
                    }
                    
                    // Personal Records
                    PersonalRecordsSection(workouts: dataManager.workouts)
                    
                    // Recent Workouts
                    RecentWorkoutsSection(workouts: dataManager.workouts.prefix(5))
                }
            }
            .navigationTitle("Progress")
        }
    }
}

struct SummaryCardsView: View {
    let workouts: [Workout]
    let metric: ProgressStatsView.Metric
    
    private var totalValue: Double {
        switch metric {
        case .volume:
            return workouts.flatMap { $0.exercises.flatMap { $0.sets } }
                .compactMap { set in
                    guard let weight = set.weight, let reps = set.reps else { return nil }
                    return weight * Double(reps)
                }
                .reduce(0, +)
        case .sets:
            return Double(workouts.flatMap { $0.exercises.flatMap { $0.sets } }.count)
        case .workouts:
            return Double(workouts.count)
        }
    }
    
    private var averageValue: Double {
        guard !workouts.isEmpty else { return 0 }
        return totalValue / Double(workouts.count)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Total \(metric.rawValue)",
                value: formatValue(totalValue),
                icon: "chart.bar.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "Average",
                value: formatValue(averageValue),
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
        }
        .padding(.horizontal)
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .volume:
            return "\(Int(value)) lbs"
        case .sets:
            return "\(Int(value))"
        case .workouts:
            return "\(Int(value))"
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProgressChartView: View {
    let data: [ChartDataPoint]
    let metric: ProgressStatsView.Metric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Over Time")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data, id: \.period) { dataPoint in
                    VStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 20, height: max(4, CGFloat(dataPoint.value / maxValue * 100)))
                            .cornerRadius(2)
                        
                        Text("\(dataPoint.period)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
}

struct ChartDataPoint {
    let period: Int
    let value: Double
}

struct PersonalRecordsSection: View {
    let workouts: [Workout]
    
    private var personalRecords: (heaviestWeight: Double, bestVolume: Double, longestWorkout: TimeInterval) {
        var heaviest: Double = 0
        var bestVolume: Double = 0
        var longest: TimeInterval = 0
        
        for workout in workouts {
            // Longest workout
            if let duration = workout.duration, duration > longest {
                longest = duration
            }
            
            for exercise in workout.exercises {
                for set in exercise.sets {
                    if let weight = set.weight, let reps = set.reps {
                        // Heaviest weight
                        if weight > heaviest {
                            heaviest = weight
                        }
                        
                        // Best volume
                        let volume = weight * Double(reps)
                        if volume > bestVolume {
                            bestVolume = volume
                        }
                    }
                }
            }
        }
        
        return (heaviest, bestVolume, longest)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(.yellow)
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                PersonalRecordRow(
                    title: "Heaviest Weight",
                    value: "\(Int(personalRecords.heaviestWeight)) lbs",
                    icon: "dumbbell.fill"
                )
                
                PersonalRecordRow(
                    title: "Best Volume",
                    value: "\(Int(personalRecords.bestVolume)) lbs",
                    icon: "chart.bar.fill"
                )
                
                PersonalRecordRow(
                    title: "Longest Workout",
                    value: formatDuration(personalRecords.longestWorkout),
                    icon: "clock.fill"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

struct PersonalRecordRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct RecentWorkoutsSection: View {
    let workouts: ArraySlice<Workout>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(workouts), id: \.id) { workout in
                    RecentWorkoutRow(workout: workout)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RecentWorkoutRow: View {
    let workout: Workout
    
    private var exerciseCount: Int {
        workout.exercises.count
    }
    
    private var completedSets: Int {
        workout.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(exerciseCount) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(completedSets) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Data Yet")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Complete some workouts to see your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ProgressStatsView()
        .environmentObject(DataManager())
}
