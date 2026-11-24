import Foundation
import Observation

@Observable
final class SleepGuard {
    static let presets: [Duration] = [30 * 60, 3_600, 2 * 3_600, 4 * 3_600, 8 * 3_600, 12 * 3_600].map(Duration.seconds)

    var kinds = Set(PowerAssertionKind.allCases) {
        didSet {
            guard isActive, kinds != oldValue else { return }
            holdAssertions()
        }
    }

    private(set) var isActive = false
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    /// Planned length of the current timed session, extensions included.
    private(set) var duration: Duration?
    private(set) var remaining: Duration?
    private(set) var failure: PowerAssertionError?

    @ObservationIgnored private var assertions: [PowerAssertion] = []
    @ObservationIgnored private var countdown: Task<Void, Never>?
    @ObservationIgnored private let refreshInterval: Duration

    init(refreshInterval: Duration = .seconds(30)) {
        self.refreshInterval = refreshInterval
    }

    /// 1 when awake without limit, the remaining share of a timer, 0 at rest.
    var progress: Double {
        guard isActive else { return 0 }
        guard let duration, let remaining, duration > .zero else { return 1 }
        return min(1, max(0, remaining / duration))
    }

    func activate(for duration: Duration? = nil) {
        deactivate()
        guard holdAssertions() else { return }

        isActive = true
        startDate = .now
        guard let duration else { return }

        self.duration = duration
        startCountdown(until: Date.now.addingTimeInterval(duration.timeInterval))
    }

    func extend(by extra: Duration) {
        guard isActive, let endDate, let duration else { return }
        self.duration = duration + extra
        startCountdown(until: endDate.addingTimeInterval(extra.timeInterval))
    }

    func deactivate() {
        countdown?.cancel()
        countdown = nil
        assertions.removeAll()
        isActive = false
        startDate = nil
        endDate = nil
        duration = nil
        remaining = nil
    }

    @discardableResult
    private func holdAssertions() -> Bool {
        do {
            // Builds the new set before dropping the old one so the Mac is never left unguarded.
            assertions = try kinds.map { kind throws(PowerAssertionError) in
                try PowerAssertion(kind, reason: "TeaShot garde le Mac éveillé")
            }
            failure = nil
            return true
        } catch {
            failure = error
            deactivate()
            return false
        }
    }

    private func startCountdown(until end: Date) {
        countdown?.cancel()
        endDate = end
        remaining = .seconds(max(0, end.timeIntervalSinceNow))
        countdown = Task { [weak self] in await self?.runCountdown(until: end) }
    }

    private func runCountdown(until end: Date) async {
        while !Task.isCancelled {
            let left = end.timeIntervalSinceNow
            guard left > 0 else {
                deactivate()
                return
            }
            remaining = .seconds(left)
            try? await Task.sleep(for: min(refreshInterval, .seconds(left)))
        }
    }
}

extension Duration {
    nonisolated var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}
