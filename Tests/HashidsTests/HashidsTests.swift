//
//  HashIdsTests.swift
//  http://hashids.org
//
//  Author https://github.com/malczak
//  Licensed under the MIT license.
//

import XCTest
import hashids

class HashIdsTests: XCTestCase
{
    
    func testSimpleHash()
    {
        var hashids = Hashids(salt: "this is my salt");
        let s = hashids.encode(1, 2, 3);
        XCTAssert(s! == "laHquq")
    }

    func testKnownHashes()
    {
        // known hashed where generated with php Hashids implementation
        let knownHashes:[String: [Int]] = [
            "laHquq": [1,2,3],
            "NV": [1],
            "xJ3MBFkB3PO": [123456,123456789],
            "NZFzBrjhl": [10,123456,1]
        ];
        
        var equalCount = 0;
        var hashids = Hashids(salt: "this is my salt");
        for expectedHash in knownHashes.keys
        {
            let values = knownHashes[expectedHash];
            if let hash = hashids.encode(values!)
            {
                if(hash == expectedHash)
                {
                    equalCount += 1;
                }
            }
        }
        
        XCTAssertEqual(equalCount, knownHashes.count);
    }
    
    func testHashMinLength()
    {
        let minHashLength = 20;
        let testRange = 1...20;
        var hashids = Hashids(salt: "this is my salt", minHashLength: numericCast(minHashLength));
        var minCount = 0;
        for i in testRange
        {
            if let hash = hashids.encode(i)
            {
                if( count(hash) > minHashLength )
                {
                    minCount += 1;
                }
            } else {
                XCTFail("Missing hash for \(i)");
            }
            
        }
        
        XCTAssertEqual(minHashLength, (testRange.endIndex - testRange.startIndex));
    }
    
    func testInstances()
    {
        let input = [1,2,3,1000];
        var hashids1 = Hashids(salt: "this is my salt", minHashLength: 9, alphabet: "abcdef0123456789");
        var hashids2 = Hashids(salt: "this is my salt", minHashLength: 9, alphabet: "abcdef0123456789");
        var hash = hashids1.encode(input);
        var values = hashids2.decode(hash);
        XCTAssertEqual(input, values);
    }
    
    func testDifferentSalts() {
        var hashids1 = Hashids(salt: "this is my salt");
        var hashids2 = Hashids(salt: "this is not my salt");
        let input = [1,2,3];
        let hash = hashids1.encode(input);
        let values = hashids2.decode(hash!);
        XCTAssertNotEqual(input, values);
    }
    
    func testUInt8Alphabet()
    {
        var alphabet = "abcdef0123456789";
        let input = [1203,311,331,423];
        var hashids = Hashids_<UInt8>(salt: "this is my salt", minHashLength: 0, alphabet: alphabet);
        var hash = hashids.encode(input);
        var values = hashids.decode(hash!);
        XCTAssertEqual(input, values);
    }
    
    func testEmojiAlphabet()
    {
        var alphabet = "🐶🐭🐹🐷🐮🐰🐹🐸";
        let input = [300122,12,3,3112,12,1000001201];
        var hashids = Hashids(salt: "this is my salt", minHashLength: 0, alphabet: alphabet);
        var hash = hashids.encode(input);
        var values = hashids.decode(hash!);
        XCTAssertEqual(input, values);
    }
    
    func testBigDataSet()
    {
        var alphabet = "abcdef0123456789";
        var input = [Int]();
        for i in 0..<100 {
            input.append(random());
        }
        var hashids = Hashids(salt: "this is my salt");
        var hash = hashids.encode(input);
        var values = hashids.decode(hash!);
        XCTAssertEqual(input, values);
    }
    
}
