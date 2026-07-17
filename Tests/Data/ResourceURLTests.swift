//
//  ResourceURLTests.swift
//  Tests
//

import Testing
@testable import rick_verse

/// Tests for `ResourceURL.trailingID(from:)` — the parser that turns the API's
/// resource URLs into domain IDs.
struct ResourceURLTests {

    @Test("Parses the trailing ID from a resource URL")
    func parsesTrailingID() {
        #expect(ResourceURL.trailingID(from: "https://rickandmortyapi.com/api/episode/42") == 42)
        #expect(ResourceURL.trailingID(from: "https://rickandmortyapi.com/api/character/1") == 1)
    }

    @Test("A multi-digit ID is parsed whole")
    func parsesMultiDigitID() {
        #expect(ResourceURL.trailingID(from: "https://rickandmortyapi.com/api/character/826") == 826)
    }

    @Test("A non-numeric tail yields nil")
    func nonNumericTailIsNil() {
        #expect(ResourceURL.trailingID(from: "https://rickandmortyapi.com/api/episode") == nil)
        #expect(ResourceURL.trailingID(from: "not-a-url") == nil)
    }

    @Test("An empty string yields nil")
    func emptyStringIsNil() {
        #expect(ResourceURL.trailingID(from: "") == nil)
    }

    /// Pins current behavior rather than asserting what's ideal: `split` drops
    /// the empty component after the trailing slash, so the ID *is* found. Worth
    /// knowing — a stricter parser would return nil here. The API never emits
    /// trailing slashes, so this is documentation, not a bug.
    @Test("A trailing slash still yields the ID (current behavior)")
    func trailingSlashStillParses() {
        #expect(ResourceURL.trailingID(from: "https://rickandmortyapi.com/api/episode/42/") == 42)
    }
}
