import Foundation
import Observation

@Observable
final class SleepGuard {
    static let presets: [Duration] = [30 * 60, 3_600, 2 * 3_600, 4 * 3_600, 8 * 3_600, 12 * 3_600].map(Duration.seconds)

    /// The assertions held while active, or held by the next activation while at rest.
    private(set) var kinds = Set(PowerAssertionKind.allCases)

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
    @ObservationIgnored private let makeAssertion: (PowerAssertionKind) throws(PowerAssertionError) -> PowerAssertion

    init(
        refreshInterval: Duration = .seconds(30),
        makeAssertion: @escaping (PowerAssertionKind) throws(PowerAssertionError) -> PowerAssertion = {
            try PowerAssertion($0, reason: "TeaShot keeps the Mac awake")
        }
    ) {
        self.refreshInterval = refreshInterval
        self.makeAssertion = makeAssertion
    }

    /// 1 when awake without limit, the remaining share of a timer, 0 at rest.
    var progress: Double {
        guard isActive else { return 0 }
        guard let duration, let remaining, duration > .zero else { return 1 }
        return min(1, max(0, remaining / duration))
    }

    /// Takes effect at once while active; if the new assertions fail, the current ones stay held.
    func use(_ newKinds: Set<PowerAssertionKind>) {
        guard isActive else {
            kinds = newKinds
            failure = nil
            return
        }
        guard newKinds != kinds else {
            failure = nil
            return
        }
        if holdAssertions(newKinds) { kinds = newKinds }
    }

    /// Starts a new session; if the assertions cannot be held, the current session, if any, carries on unchanged.
    func activate(for duration: Duration? = nil, holding newKinds: Set<PowerAssertionKind>? = nil) {
        let newKinds = newKinds ?? kinds
        guard holdAssertions(newKinds) else { return }

        kinds = newKinds
        countdown?.cancel()
        countdown = nil
        isActive = true
        startDate = .now
        endDate = nil
        remaining = nil
        self.duration = duration
        guard let duration else { return }

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
        failure = nil
    }

    private func holdAssertions(_ kinds: Set<PowerAssertionKind>) -> Bool {
        do {
            // Builds the new set before dropping the old one so the Mac is never left unguarded.
            assertions = try kinds.map { kind throws(PowerAssertionError) in try makeAssertion(kind) }
            failure = nil
            return true
        } catch {
            failure = error
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
