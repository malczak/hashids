//
//  HashIds.swift
//  HashIds
//
//  Created by malczak on 04/02/15.
//  Copyright (c) 2015 thepiratecat. All rights reserved.
//

import Foundation

class Hashids
{
    private let MIN_ALPHABET_LENGTH:Int = 16;
    
    private let SEP_DIV:Double = 3.5;
    
    private let GUARD_DIV:Double = 12;
    
    private var minHashLength:UInt;
    
    private var alphabet:[UInt32];
    
    private var seps:[UInt32];

    private var salt:[UInt32];
    
    private var guards:[UInt32];
    

    init(salt:String!, minHashLength:UInt = 0, alphabet:String? = nil)
    {
        var _alphabet = (alphabet != nil) ? alphabet! : "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        var _seps = "cfhistuCFHISTU";
//var o = map(scalars){ $0.value }
        
        self.minHashLength = minHashLength;
        self.guards = [UInt32]();
        self.salt = map(salt.unicodeScalars){ $0.value };
        self.seps = map(_seps.unicodeScalars){ $0.value };
        self.alphabet = unique( map(_alphabet.unicodeScalars){ $0.value } );
        
        self.seps = intersection(self.alphabet, self.seps);
        self.alphabet = difference(self.alphabet, self.seps);
        shuffle(&self.seps, self.salt);

        
        let sepsLength = self.seps.count;
        let alphabetLength = self.alphabet.count;
        
        if ( (0 == sepsLength) || (Double(alphabetLength) / Double(sepsLength) > self.SEP_DIV) ) {
            
            var newSepsLength = Int(ceil(Double(alphabetLength) / self.SEP_DIV));
            
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
        
        let guard = Int(ceil(Double(alphabetLength)/self.GUARD_DIV));
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

    func encode(value:Int...) -> String?
    {
        let ret = _encode(value);
        return ret.reduce(String(), combine: { (var so, i) in so.append(UnicodeScalar(i)); return so });
    }
    
    func decode(value:String!) -> [Int]
    {
        let trimmed = value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
        let hash = map(trimmed.unicodeScalars){ $0.value };
        return self._decode(hash);
    }
    
    func encode_hex()
    {
        
    }
    
    func decode_hex()
    {
        
    }
    
    func _encode(numbers:[Int]) -> [UInt32]
    {
        var alphabet = self.alphabet;
        var numbers_hash_int = 0;

        for (index, value) in enumerate(numbers)
        {
            numbers_hash_int += ( value  % ( index + 100 ) );
        }
        
        let lottery = alphabet[numbers_hash_int % alphabet.count];
        var ret = [lottery];
        
        for (index, value) in enumerate(numbers)
        {
            let lsalt = ([lottery] + self.salt + alphabet)[0..<(alphabet.count)];
            shuffle(&alphabet, lsalt);
            let last = _hash(value, alphabet);
            ret += last;
            
            if(index + 1 < numbers.count)
            {
                let number = value % (numericCast(last[0]) + index);
                let seps_index = number % self.seps.count;
                ret.append(self.seps[seps_index]);
            }
        }
        
        let minLength:Int = numericCast(self.minHashLength);
        
        if(ret.count < minLength)
        {
            let guard_index = (numbers_hash_int + numericCast(ret[0])) % self.guards.count;
            let guard = self.guards[guard_index];
            ret.insert(guard, atIndex: 0);
            
            if(ret.count < minLength)
            {
                let guard_index = (numbers_hash_int + numericCast(ret[2])) % self.guards.count;
                let guard = self.guards[guard_index];
                ret.append(guard);
            }
        }
        
        let half_length = alphabet.count >> 1;
        while( ret.count < minLength )
        {
            shuffle(&alphabet, alphabet);
            let lrange = 0..<half_length;
            let rrange = half_length..<(alphabet.count);
            ret = alphabet[rrange] + ret + alphabet[lrange];
            
            let excess = ret.count - half_length;
            if( excess > 0 )
            {
                let start = excess>>1;
                ret = [UInt32](ret[start..<(start+half_length)])
            }
        }
        
        return ret;
    }
    
    func _decode(hash:[UInt32]) -> [Int]
    {
        var ret = [Int]();
        
        var alphabet = self.alphabet;

        var hashes = split(hash, { contains(self.guards, $0) }, maxSplit: hash.count, allowEmptySlices: true);
        
        let hashesCount = hashes.count, i = ((hashesCount == 2) || (hashesCount == 3)) ? 1 : 0;
        
        let hash = hashes[i];
        if(hash.count > 0)
        {
            let lottery = hash[0];
            let valuesHashes = hash[1..<hash.count];
            var valueHashes = split(valuesHashes, { contains(self.seps, $0) }, maxSplit: valuesHashes.count, allowEmptySlices: true);
            
            for subHash in valueHashes
            {
                let lsalt = ([lottery] + self.salt + alphabet)[0..<(alphabet.count)];
                shuffle(&alphabet, lsalt);
                ret.append(self._unhash(subHash, alphabet));
            }
        }
        
        return ret;
    }
    
    func _hash(var number:Int, _ alphabet:[UInt32]) -> [UInt32]
    {
        var hash = [UInt32]();
        let length = alphabet.count
        
        do {
            hash.insert(alphabet[number % length], atIndex: 0);
            number = number / length;
        } while( number != 0 );
        
        return hash;
    }

    func _unhash<T:CollectionType where T.Index == Int, T.Generator.Element == UInt32 >(hash:T, _ alphabet:[UInt32]) -> Int
    {
        var value:Double = 0;

        let hashLength = countElements(hash)
        if (hashLength > 0)
        {
            let alphabetLength = alphabet.count;
            
            for (index, token) in enumerate(hash)
            {
                if let token_index = find(alphabet, token)
                {
                    let mul = pow(Double(alphabetLength), Double(hashLength - index - 1));
                    value += Double(token_index) * mul;
                }
            }
        }
        
        return Int(trunc(value));
    }
    
    func combine(s1:String, s2:String?, cmpr:(String, Character) -> Bool) -> String
    {
        if s2 != nil {
            var o = String();
            for c in s1
            {
                if cmpr(s2!,c) {
                    o.append(c);
                }
            }
            return o;
        }
        return s1;
    }

}



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

/*
internal func shuffle(inout a:[Int32], b:[Int32])
{
    var sidx = a.count - 1, scnt = b.count, vidx = 0, v = 0, _p = 0, _i = 0, _j = 0;
    while(sidx > 0)
    {
        v = v % scnt;
        _i = numericCast(b[v]);
        _p += _i;
        _j = (_i + v + _p) % sidx;
        let tmp = a[sidx];
        a[sidx] = a[_j];
        a[_j] = tmp;
        v += 1;
        sidx -= 1;
    }
}
*/

internal func shuffle<T:MutableCollectionType, U:CollectionType where T.Generator.Element == UInt32, T.Index == Int, T.Generator.Element == U.Generator.Element, T.Index == U.Index>(inout source:T, salt:U)
{
    var sidx = countElements(source) - 1, scnt = countElements(salt), vidx = salt.startIndex, v = 0, _p = 0, _i = 0, _j = 0;
    while(sidx > 0)
    {
        v = v % scnt;
        _i = numericCast(salt[v]);
        _p += _i;
        _j = (_i + v + _p) % sidx;
        let tmp = source[sidx];
        source[sidx] = source[_j];
        source[_j] = tmp;
        v += 1;
        sidx -= 1;
    }
}
