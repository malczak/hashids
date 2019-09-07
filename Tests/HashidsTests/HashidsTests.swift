//
//  HashIdsTests.swift
//  http://hashids.org
//
//  Author https://github.com/malczak
//  Licensed under the MIT license.
//

import XCTest
import Hashids_Swift

class HashIdsTests: XCTestCase {
    
    func testEmptySalt() {
        let input = [12, 45, 11]
        let hashids = Hashids(salt: "")
        let s = hashids.encode(input)
        XCTAssertNotNil(s)
        
        let i = hashids.decode(s!)
        XCTAssert(input == i)
    }
    
    func testSimpleHash() {
        let hashids = Hashids(salt: "this is my salt")
        let s = hashids.encode(1, 2, 3)
        XCTAssert(s! == "laHquq")
    }
    
    func testSimpleRun() {
        let set = [1, 2, 3]
        let hashids = Hashids(salt: "this is my salt")
        let encoded = hashids.encode(set)
        let decoded = hashids.decode(encoded)
        XCTAssert(decoded == set)
    }
    
    func testMultipleRuns() {
        let hashids = Hashids(salt: "this is my salt")
        let s = hashids.encode(1, 2, 3)
        var equal = true
        for _ in 0 ... 10 {
            equal = equal && (s == hashids.encode(1, 2, 3))
        }
        XCTAssertTrue(equal)
    }
    
    func testKnownHashes() {
        // known hashed where generated with php Hashids implementation
        let knownHashes: [String:[Int]] = [
            "laHquq": [1, 2, 3],
            "NV": [1],
            "xJ3MBFkB3PO": [123456, 123456789],
            "NZFzBrjhl": [10, 123456, 1]
        ]
        
        var equalCount = 0
        let hashids = Hashids(salt: "this is my salt")
        for expectedHash in knownHashes.keys {
            let values = knownHashes[expectedHash]
            if let hash = hashids.encode(values!) {
                if (hash == expectedHash) {
                    equalCount += 1
                }
            }
        }
        
        XCTAssertEqual(equalCount, knownHashes.count)
    }
    
    func testKnownHashesWithHashLengthAndAlphabet() {
        // known hashes where generated with js Hashids implementation
        // http://codepen.io/anon/pen/MbmpJP
        let knownHashes: [String:[Int]] = [
            "GlaHquq0": [1, 2, 3],
            "gB0NV05e": [1],
            "xJ3MBFkB3PO": [123456, 123456789],
            "NZFzBrjhl": [10, 123456, 1]
        ]
        
        var equalCount = 0
        let hashids = Hashids(salt: "this is my salt", minHashLength: 8, alphabet: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
        for expectedHash in knownHashes.keys {
            let values = knownHashes[expectedHash]
            if let hash = hashids.encode(values!) {
                if (hash == expectedHash) {
                    equalCount += 1
                }
            }
        }
        
        XCTAssertEqual(equalCount, knownHashes.count)
    }
    
    
    func testCaseForIssue15() {
        let knownHashes: [String:[Int]] = [
            "n1EOZmo3bKArd9YCpHPd742kWewMpvPR": [1, 2, 8]
        ]
        
        var equalCount = 0
        let hashids = Hashids(salt: "icaslntrigresnisteet",
                              minHashLength: 32,
                              alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890")
        for expectedHash in knownHashes.keys {
            let values = knownHashes[expectedHash]
            if let hash = hashids.encode(values!) {
                print(hash, "\n", expectedHash, "\n")
                if (hash == expectedHash) {
                    equalCount += 1
                }
            }
        }
        
        XCTAssertEqual(equalCount, knownHashes.count)
    }
    
    func testHashMinLength() {
        let minHashLength = 20
        let testRange = 1 ... 20
        let hashids = Hashids(salt: "this is my salt", minHashLength: numericCast(minHashLength))
        var minCount = 0
        for i in testRange {
            if let hash = hashids.encode(i) {
                if (hash.count > minHashLength) {
                    minCount += 1
                }
            } else {
                XCTFail("Missing hash for \(i)")
            }
            
        }
        
        XCTAssertEqual(minHashLength, testRange.count)
    }
    
    func testInstances() {
        let input = [1, 2, 3, 1000]
        let hashids1 = Hashids(salt: "this is my salt", minHashLength: 9, alphabet: "abcdef0123456789")
        let hashids2 = Hashids(salt: "this is my salt", minHashLength: 9, alphabet: "abcdef0123456789")
        let hash = hashids1.encode(input)
        let values = hashids2.decode(hash)
        XCTAssertEqual(input, values)
    }
    
    func testDifferentSalts() {
        let hashids1 = Hashids(salt: "this is my salt")
        let hashids2 = Hashids(salt: "this is not my salt")
        let input = [1, 2, 3]
        let hash = hashids1.encode(input)
        let values = hashids2.decode(hash!)
        XCTAssertNotEqual(input, values)
    }
    
    func testUInt8Alphabet() {
        let alphabet = "abcdef0123456789"
        let input = [1203, 311, 331, 423]
        let hashids = Hashids_<UInt8>(salt: "this is my salt", minHashLength: 0, alphabet: alphabet)
        let hash = hashids.encode(input)
        let values = hashids.decode(hash!)
        XCTAssertEqual(input, values)
    }
    
    func testEmojiAlphabet() {
        let alphabet = "🐶🐭🐹🐷🐮🐰🐹🐸"
        let input = [300122, 12, 3, 3112, 12, 1000001201]
        let hashids = Hashids(salt: "this is my salt", minHashLength: 0, alphabet: alphabet)
        let hash = hashids.encode(input)
        let values = hashids.decode(hash!)
        XCTAssertEqual(input, values)
    }
    
    func testBigDataSet() {
        var input = [Int]()
        for _ in 0 ..< 100 {
            input.append(Int(arc4random()))
        }
        let hashids = Hashids(salt: "this is my salt")
        let hash = hashids.encode(input)
        let values = hashids.decode(hash!)
        XCTAssertEqual(input, values)
    }
    
    func testInt64() {
        let input: Int64 = 111_111_111_1112
        let hashids = Hashids(salt: "this is my salt")
        let hash = hashids.encode(input)
        let values = hashids.decode64(hash!)
        XCTAssertEqual(input, values.first)
    }
    
}
