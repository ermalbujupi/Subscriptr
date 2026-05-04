import Foundation
import SwiftData
import SwiftUI

@Observable
final class DashboardViewModel {
    var subscriptions: [Subscription] = []

    var activeSubscriptions: [Subscription] {
        subscriptions.filter(\.isActive)
    }

    var totalMonthlySpend: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    var activeCount: Int {
        activeSubscriptions.count
    }
}
