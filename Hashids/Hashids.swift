//
//  HashIds.swift
//  http://hashids.org
//
//  Author https://github.com/malczak
//  Licensed under the MIT license.
//

import Foundation

// MARK: Hashids options

public struct HashidsOptions
{
    static let VERSION = "1.1.0";
    
    static var MIN_ALPHABET_LENGTH:Int = 16;
    
    static var SEP_DIV:Double = 3.5;
    
    static var GUARD_DIV:Double = 12;
    
    static var ALPHABET:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    
    static var SEPARATORS:String = "cfhistuCFHISTU";
}


// MARK: Hashids protocol

public protocol HashidsGenerator
{
    typealias Char;
    
    func encode(value:Int...) -> String?
    
    func encode(values:[Int]) -> String?
    
    func decode(value:String!) -> [Int]
    
    func decode(value:[Char]) -> [Int]
    
}


// MARK: Hashids class

public typealias Hashids = Hashids_<UInt32>


// MARK: Hashids generic class

public class Hashids_<T where T:Equatable, T:UnsignedIntegerType> : HashidsGenerator
{
    typealias Char = T;
    
    private var minHashLength:UInt;
    
    private var alphabet:[Char];
    
    private var seps:[Char];

    private var salt:[Char];
    
    private var guards:[Char];
    
    public init(salt:String!, minHashLength:UInt = 0, alphabet:String? = nil)
    {
        var _alphabet = (alphabet != nil) ? alphabet! : HashidsOptions.ALPHABET;
        var _seps = HashidsOptions.SEPARATORS;
        
        self.minHashLength = minHashLength;
        self.guards = [Char]();
        self.salt = map(salt.unicodeScalars){ numericCast($0.value) };
        self.seps = map(_seps.unicodeScalars){ numericCast($0.value) };
        self.alphabet = unique( map(_alphabet.unicodeScalars){ numericCast($0.value) } );
        
        self.seps = intersection(self.alphabet, self.seps);
        self.alphabet = difference(self.alphabet, self.seps);
        shuffle(&self.seps, self.salt);

        
        let sepsLength = self.seps.count;
        let alphabetLength = self.alphabet.count;
        
        if ( (0 == sepsLength) || (Double(alphabetLength) / Double(sepsLength) > HashidsOptions.SEP_DIV) ) {
            
            var newSepsLength = Int(ceil(Double(alphabetLength) / HashidsOptions.SEP_DIV));
            
            if(1 == newSepsLength) {
                newSepsLength += 1;
            }
            
            if(newSepsLength > sepsLength)
            {
                let diff = advance(self.alphabet.startIndex, newSepsLength - sepsLength);
                let range = 0..<diff;
                self.seps += self.alphabet[range];
                self.alphabet.removeRange(range);
            } else
            {
                let pos = advance(self.seps.startIndex,newSepsLength);
                self.seps.removeRange(pos+1..<self.seps.count);
            }
        }
        
        shuffle(&self.alphabet, self.salt);
        
        let guard = Int(ceil(Double(alphabetLength)/HashidsOptions.GUARD_DIV));
        if(alphabetLength < 3)
        {
            let seps_guard = advance(self.seps.startIndex,guard);
            let range = 0..<seps_guard;
            self.guards += self.seps[range];
            self.seps.removeRange(range);
        } else
        {
            let alphabet_guard = advance(self.alphabet.startIndex,guard);
            let range = 0..<alphabet_guard;
            self.guards += self.alphabet[range];
            self.alphabet.removeRange(range);
        }
    }
    
    // MARK: public api

    public func encode(value:Int...) -> String?
    {
        return encode(value);
    }
    
    public func encode(values:[Int]) -> String?
    {
        let ret = _encode(values);
        return ret.reduce(String(), combine: { (var so, i) in
            let scalar:UInt32 = numericCast(i);
            so.append(UnicodeScalar(scalar));
            return so
        });
    }
    
    public func decode(value:String!) -> [Int]
    {
        let trimmed = value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
        let hash:[Char] = map(trimmed.unicodeScalars){ numericCast($0.value) };
        return self.decode(hash);
    }
    
    public func decode(value:[Char]) -> [Int]
    {
        return self._decode(value);
    }
    
    // MARK: private funcitons 
    
    private func _encode(numbers:[Int]) -> [Char]
    {
        var alphabet = self.alphabet;
        var numbers_hash_int = 0;

        for (index, value) in enumerate(numbers)
        {
            numbers_hash_int += ( value  % ( index + 100 ) );
        }
        
        let lottery = alphabet[numbers_hash_int % alphabet.count];
        var hash = [lottery];
  
        var lsalt = [Char]();
        let (lsaltARange, lsaltRange) = _saltify(&lsalt, lottery, alphabet);
        
        for (index, value) in enumerate(numbers)
        {
            shuffle(&alphabet, lsalt, lsaltRange);
            let lastIndex = hash.endIndex;
            _hash(&hash, value, alphabet);
            
            if(index + 1 < numbers.count)
            {
                let number = value % (numericCast(hash[lastIndex]) + index);
                let seps_index = number % self.seps.count;
                hash.append(self.seps[seps_index]);
            }
            
            lsalt.replaceRange(lsaltARange, with: alphabet);
        }
        
        let minLength:Int = numericCast(self.minHashLength);
        
        if(hash.count < minLength)
        {
            let guard_index = (numbers_hash_int + numericCast(hash[0])) % self.guards.count;
            let guard = self.guards[guard_index];
            hash.insert(guard, atIndex: 0);
            
            if(hash.count < minLength)
            {
                let guard_index = (numbers_hash_int + numericCast(hash[2])) % self.guards.count;
                let guard = self.guards[guard_index];
                hash.append(guard);
            }
        }
        
        let half_length = alphabet.count >> 1;
        while( hash.count < minLength )
        {
            shuffle(&alphabet, alphabet);
            let lrange = 0..<half_length;
            let rrange = half_length..<(alphabet.count);
            hash = alphabet[rrange] + hash + alphabet[lrange];
            
            let excess = hash.count - minLength;
            if( excess > 0 )
            {
                let start = excess >> 1;
                hash = [Char](hash[start..<(start+minLength)])
            }
        }
        
        return hash;
    }
    
    private func _decode(hash:[Char]) -> [Int]
    {
        var ret = [Int]();
        
        var alphabet = self.alphabet;
        
        var hashes = split(hash, maxSplit: hash.count, allowEmptySlices: true) { contains(self.guards, $0) };
        let hashesCount = hashes.count, i = ((hashesCount == 2) || (hashesCount == 3)) ? 1 : 0;
        let hash = hashes[i];
        
        if(hash.count > 0)
        {
            let lottery = hash[0];
            let valuesHashes = hash[1..<hash.count];
            let valueHashes = split(valuesHashes, maxSplit: valuesHashes.count, allowEmptySlices: true)  { contains(self.seps, $0) };

            var lsalt = [Char]();
            let (lsaltARange, lsaltRange) = _saltify(&lsalt, lottery, alphabet);

            for subHash in valueHashes
            {
                shuffle(&alphabet, lsalt, lsaltRange);
                ret.append(self._unhash(subHash, alphabet));
                lsalt.replaceRange(lsaltARange, with: alphabet);
            }
        }
        
        return ret;
    }
    
    private func _hash(inout hash:[Char], var _ number:Int, _ alphabet:[Char])
    {
        let length = alphabet.count, index = hash.count;
        do {
            hash.insert(alphabet[number % length], atIndex: index);
            number = number / length;
        } while( number != 0 );
    }

    private func _unhash<U:CollectionType where U.Index == Int, U.Generator.Element == Char>(hash:U, _ alphabet:[Char]) -> Int
    {
        var value:Double = 0;

        let hashLength = count(hash)
        if (hashLength > 0)
        {
            let alphabetLength = alphabet.count;
            
            for index in hash.startIndex..<hash.endIndex
            {
                let token = hash[index];
                if let token_index = find(alphabet, token as Char)
                {
                    let mul = pow(Double(alphabetLength), Double(hashLength - index - 1));
                    value += Double(token_index) * mul;
                }
            }
        }
        
        return Int(trunc(value));
    }
    
    private func _saltify(inout salt:[Char], _ lottery:Char, _ alphabet:[Char]) -> (Range<Int>, Range<Int>)
    {
        salt.append(lottery);
        salt = salt + self.salt;
        salt = salt + alphabet;
        let lsaltARange = (self.salt.count + 1)..<salt.count;
        let lsaltRange = 0..<alphabet.count;
        return (lsaltARange, lsaltRange);
    }
   
}

// MARK: Internal functions

internal func contains<T:CollectionType where T.Generator.Element:Equatable>(a:T, e:T.Generator.Element) -> Bool
{
    return (find(a,e) != nil);
}

internal func transform<T:CollectionType where T.Generator.Element:Equatable>(a: T, b: T, cmpr: (inout Array<T.Generator.Element>, T, T, T.Generator.Element ) -> Void ) -> [T.Generator.Element]
{
    typealias U = T.Generator.Element;
    var c = [U]();
    for i in a
    {
        cmpr(&c, a, b, i);
    }
    return c;
}

internal func unique<T:CollectionType where T.Generator.Element:Equatable>(a:T) -> [T.Generator.Element]
{
    return transform(a, a) { (var c, a, b, e) in
        if(!contains(c, e))
        {
            c.append(e);
        };
    }
}

internal func intersection<T:CollectionType where T.Generator.Element:Equatable>(a:T, b:T) -> [T.Generator.Element]
{
    return transform(a, b) { (var c, a, b, e) in
        if(contains(b, e))
        {
            c.append(e);
        };
    }
}

internal func difference<T:CollectionType where T.Generator.Element:Equatable>(a:T, b:T) -> [T.Generator.Element]
{
    return transform(a, b) { (var c, a, b, e) in
        if(!contains(b, e))
        {
            c.append(e);
        };
    }
}
internal func shuffle<T:MutableCollectionType, U:CollectionType where T.Index == Int, T.Generator.Element:UnsignedIntegerType, T.Generator.Element == U.Generator.Element, T.Index == U.Index>(inout source:T, salt:U)
{
    return shuffle(&source, salt, 0..<count(salt));
}

internal func shuffle<T:MutableCollectionType, U:CollectionType where T.Index == Int, T.Generator.Element:UnsignedIntegerType, T.Generator.Element == U.Generator.Element, T.Index == U.Index>(inout source:T, salt:U, saltRange:Range<Int>)
{
    let sidx0 = saltRange.startIndex, scnt = (saltRange.endIndex - saltRange.startIndex);
    var sidx = count(source) - 1, v = 0, _p = 0;
    while(sidx > 0)
    {
        v = v % scnt;
        let _i:Int = numericCast(salt[sidx0 + v]);
        _p += _i;
        let _j:Int = (_i + v + _p) % sidx;
        let tmp = source[sidx];
        source[sidx] = source[_j];
        source[_j] = tmp;
        v += 1;
        sidx -= 1;
    }
}
