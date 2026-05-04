import Foundation
import SwiftData

@Model
final class Card {
    var name: String
    var lastFourDigits: String

    @Relationship(inverse: \Subscription.card) var subscriptions: [Subscription]

    init(name: String, lastFourDigits: String) {
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.subscriptions = []
    }
}
