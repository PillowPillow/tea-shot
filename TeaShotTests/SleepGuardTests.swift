import Foundation
import IOKit.pwr_mgt
import Testing
@testable import TeaShot

@Suite(.serialized)
struct SleepGuardTests {
    @Test func activateHoldsEveryRequestedAssertion() {
        let sleepGuard = SleepGuard()
        sleepGuard.activate()
        defer { sleepGuard.deactivate() }

        #expect(sleepGuard.isActive)
        #expect(sleepGuard.endDate == nil)
        #expect(sleepGuard.startDate != nil)
        #expect(sleepGuard.failure == nil)
        #expect(heldAssertionTypes() == allTypes)
    }

    @Test func activateHoldsOnlyTheConfiguredKinds() {
        let sleepGuard = SleepGuard()
        sleepGuard.kinds = [.preventIdleSystemSleep, .preventDisplaySleep]
        sleepGuard.activate()
        defer { sleepGuard.deactivate() }

        #expect(heldAssertionTypes() == ["PreventUserIdleSystemSleep", "PreventUserIdleDisplaySleep"])
    }

    @Test func changingKindsWhileActiveUpdatesHeldAssertions() {
        let sleepGuard = SleepGuard()
        sleepGuard.activate()
        defer { sleepGuard.deactivate() }

        sleepGuard.kinds = [.preventIdleSystemSleep]

        #expect(sleepGuard.isActive)
        #expect(heldAssertionTypes() == ["PreventUserIdleSystemSleep"])
    }

    @Test func deactivateReleasesAssertions() {
        let sleepGuard = SleepGuard()
        sleepGuard.activate()
        sleepGuard.deactivate()

        #expect(!sleepGuard.isActive)
        #expect(sleepGuard.startDate == nil)
        #expect(heldAssertionTypes().isEmpty)
    }

    @Test func timedActivationExpiresOnItsOwn() async throws {
        let sleepGuard = SleepGuard(refreshInterval: .milliseconds(50))
        sleepGuard.activate(for: .milliseconds(300))
        #expect(sleepGuard.isActive)
        #expect(sleepGuard.endDate != nil)

        try await waitUntil { !sleepGuard.isActive }

        #expect(sleepGuard.remaining == nil)
        #expect(heldAssertionTypes().isEmpty)
    }

    @Test func reactivatingCancelsThePreviousTimer() async throws {
        let sleepGuard = SleepGuard(refreshInterval: .milliseconds(50))
        sleepGuard.activate(for: .milliseconds(200))
        sleepGuard.activate()
        defer { sleepGuard.deactivate() }

        try await Task.sleep(for: .milliseconds(500))

        #expect(sleepGuard.isActive)
        #expect(sleepGuard.endDate == nil)
    }

    @Test func remainingCountsDown() async throws {
        let sleepGuard = SleepGuard(refreshInterval: .milliseconds(50))
        sleepGuard.activate(for: .seconds(60))
        defer { sleepGuard.deactivate() }

        try await waitUntil { sleepGuard.remaining != nil }

        let remaining = try #require(sleepGuard.remaining)
        #expect(remaining > .seconds(55) && remaining <= .seconds(60))
    }

    @Test func extendPushesTheEndAndKeepsRunning() async throws {
        let sleepGuard = SleepGuard(refreshInterval: .milliseconds(50))
        sleepGuard.activate(for: .milliseconds(300))
        defer { sleepGuard.deactivate() }
        let originalEnd = try #require(sleepGuard.endDate)

        sleepGuard.extend(by: .seconds(30))

        let newEnd = try #require(sleepGuard.endDate)
        #expect(newEnd.timeIntervalSince(originalEnd) == 30)
        #expect(sleepGuard.duration == .milliseconds(30_300))
        try await Task.sleep(for: .milliseconds(500))
        #expect(sleepGuard.isActive)
    }

    @Test func extendIsIgnoredWithoutATimer() {
        let sleepGuard = SleepGuard()
        sleepGuard.activate()
        defer { sleepGuard.deactivate() }

        sleepGuard.extend(by: .seconds(30))

        #expect(sleepGuard.endDate == nil)
        #expect(sleepGuard.duration == nil)
    }

    @Test func progressReflectsRemainingShare() async throws {
        let sleepGuard = SleepGuard(refreshInterval: .milliseconds(50))
        #expect(sleepGuard.progress == 0)

        sleepGuard.activate()
        #expect(sleepGuard.progress == 1)

        sleepGuard.activate(for: .seconds(100))
        defer { sleepGuard.deactivate() }
        try await waitUntil { sleepGuard.remaining != nil }
        #expect(sleepGuard.progress > 0.95 && sleepGuard.progress <= 1)
    }
}

private let allTypes = Set(PowerAssertionKind.allCases.map(\.rawValue))

private func heldAssertionTypes() -> Set<String> {
    var byProcess: Unmanaged<CFDictionary>?
    guard IOPMCopyAssertionsByProcess(&byProcess) == kIOReturnSuccess,
          let all = byProcess?.takeRetainedValue() as? [NSNumber: [[String: Any]]]
    else { return [] }

    let mine = all[NSNumber(value: ProcessInfo.processInfo.processIdentifier)] ?? []
    return Set(mine.compactMap { $0[kIOPMAssertionTypeKey] as? String }).intersection(allTypes)
}

func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else {
            Issue.record("Condition not met within \(timeout)")
            return
        }
        try await Task.sleep(for: .milliseconds(20))
    }
}
