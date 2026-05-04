import Foundation
import SwiftData

enum BillingCycle: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var monthlyMultiplier: Double {
        switch self {
        case .weekly: return 52.0 / 12.0
        case .monthly: return 1.0
        case .yearly: return 1.0 / 12.0
        }
    }

    var yearlyMultiplier: Double {
        switch self {
        case .weekly: return 52.0
        case .monthly: return 12.0
        case .yearly: return 1.0
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case entertainment = "Entertainment"
    case music = "Music"
    case productivity = "Productivity"
    case cloud = "Cloud Storage"
    case fitness = "Fitness"
    case news = "News"
    case education = "Education"
    case utilities = "Utilities"
    case other = "Other"

    var icon: String {
        switch self {
        case .entertainment: return "tv"
        case .music: return "music.note"
        case .productivity: return "briefcase"
        case .cloud: return "cloud"
        case .fitness: return "figure.run"
        case .news: return "newspaper"
        case .education: return "book"
        case .utilities: return "wrench.and.screwdriver"
        case .other: return "ellipsis.circle"
        }
    }

    var color: String {
        switch self {
        case .entertainment: return "E74C3C"
        case .music: return "E91E63"
        case .productivity: return "3498DB"
        case .cloud: return "1ABC9C"
        case .fitness: return "F39C12"
        case .news: return "9B59B6"
        case .education: return "2ECC71"
        case .utilities: return "607D8B"
        case .other: return "95A5A6"
        }
    }
}

@Model
final class Subscription {
    var name: String
    var amount: Double
    var billingCycle: BillingCycle
    var startDate: Date
    var cancelledDate: Date?
    var category: Category
    var notes: String

    @Relationship var card: Card?

    var isActive: Bool {
        cancelledDate == nil
    }

    var monthlyAmount: Double {
        amount * billingCycle.monthlyMultiplier
    }

    var yearlyAmount: Double {
        amount * billingCycle.yearlyMultiplier
    }

    var nextRenewalDate: Date? {
        guard isActive else { return nil }
        let calendar = Calendar.current
        var date = startDate
        let now = Date()

        while date <= now {
            switch billingCycle {
            case .weekly:
                date = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            case .monthly:
                date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
            case .yearly:
                date = calendar.date(byAdding: .year, value: 1, to: date) ?? date
            }
        }
        return date
    }

    init(
        name: String,
        amount: Double,
        billingCycle: BillingCycle = .monthly,
        startDate: Date = .now,
        cancelledDate: Date? = nil,
        category: Category = .other,
        notes: String = "",
        card: Card? = nil
    ) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.cancelledDate = cancelledDate
        self.category = category
        self.notes = notes
        self.card = card
    }
}
