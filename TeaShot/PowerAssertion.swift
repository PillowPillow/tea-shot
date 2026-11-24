import Foundation
import IOKit.pwr_mgt

// Raw values mirror the IOPMLib.h CFSTR macros, which Swift cannot import.
nonisolated enum PowerAssertionKind: String, CaseIterable, Sendable {
    /// `caffeinate -d`
    case preventDisplaySleep = "PreventUserIdleDisplaySleep"
    /// `caffeinate -i`
    case preventIdleSystemSleep = "PreventUserIdleSystemSleep"
    /// `caffeinate -m`
    case preventDiskIdle = "PreventDiskIdle"
    /// `caffeinate -s`, honoured by macOS only on AC power.
    case preventSystemSleep = "PreventSystemSleep"
}

nonisolated struct PowerAssertionError: LocalizedError, Sendable {
    let kind: PowerAssertionKind
    let code: IOReturn

    var errorDescription: String? {
        "Impossible de créer l'assertion \(kind.rawValue) (code \(code))."
    }
}

/// Holds one IOKit power assertion for as long as the instance is alive.
nonisolated final class PowerAssertion: Sendable {
    let kind: PowerAssertionKind
    private let id: IOPMAssertionID

    init(_ kind: PowerAssertionKind, reason: String) throws(PowerAssertionError) {
        var id = IOPMAssertionID(0)
        let code = IOPMAssertionCreateWithName(
            kind.rawValue as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        guard code == kIOReturnSuccess else { throw PowerAssertionError(kind: kind, code: code) }
        self.kind = kind
        self.id = id
    }

    deinit {
        IOPMAssertionRelease(id)
    }
}
