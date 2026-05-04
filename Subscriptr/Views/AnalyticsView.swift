import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(
        filter: #Predicate<Subscription> { $0.cancelledDate == nil },
        sort: \Subscription.name
    ) private var activeSubscriptions: [Subscription]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statGrid
                    categoryChart
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
        }
    }

    private var totalMonthly: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    private var totalYearly: Double {
        activeSubscriptions.reduce(0) { $0 + $1.yearlyAmount }
    }

    private var averagePerSub: Double {
        guard !activeSubscriptions.isEmpty else { return 0 }
        return totalMonthly / Double(activeSubscriptions.count)
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Monthly Spend",
                value: totalMonthly,
                icon: "calendar",
                color: .accentColor
            )
            StatCard(
                title: "Yearly Projection",
                value: totalYearly,
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            StatCard(
                title: "Avg per Sub",
                value: averagePerSub,
                icon: "divide",
                color: .purple
            )
            StatCard(
                title: "Active Subs",
                value: Double(activeSubscriptions.count),
                icon: "checkmark.circle",
                color: .green,
                isCurrency: false
            )
        }
    }

    private var categoryData: [(category: Category, total: Double)] {
        Dictionary(grouping: activeSubscriptions, by: \.category)
            .map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.monthlyAmount }) }
            .sorted { $0.total > $1.total }
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spend by Category")
                .font(.headline)

            if categoryData.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.bar",
                    description: Text("Add subscriptions to see category breakdown")
                )
                .frame(minHeight: 200)
            } else {
                Chart(categoryData, id: \.category) { item in
                    BarMark(
                        x: .value("Amount", item.total),
                        y: .value("Category", item.category.rawValue)
                    )
                    .foregroundStyle(Color(hexString: item.category.color))
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(item.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(categoryData.count) * 44 + 20)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var isCurrency: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            if isCurrency {
                Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title2.weight(.bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } else {
                Text("\(Int(value))")
                    .font(.title2.weight(.bold))
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Subscription.self, Card.self], inMemory: true)
}
