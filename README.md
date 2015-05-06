## Hashids.swift
----
A Swift class to generate YouTube-like ids from numbers.

Ported from [Hashids.php](https://github.com/ivanakimov/hashids.php) by [ivanakimov](https://github.com/ivanakimov)

Read documentation at [http://hashids.org/php](http://hashids.org/php)

#### Example Usage
```swift
var hashids = Hashids(salt:"this is my salt");
var hash = hashids.encode(1, 2, 3); // hash:"laHquq"
var values = hashids.decode(hash!); // values:[1,2,3]
```
Example with custom alphabet and minimum hash length
```swift
var hashids = Hashids(salt:"this is my salt", minHashLength:8, alphabet:"abcdefghij1234567890");
var hash = hashids.encode(1, 2, 3); // hash:"514cdi42"
var values = hashids.decode(s!); // values:[1,2,3]
```
Example with UTF8 alphabet 
```swift
var hashids = Hashids(salt:"this is my salt", minHashLength:0, alphabet:"▁▂▃▄▅▆▇█");
var hash = hashids.encode(1, 2, 3); // hash:"▅▅▂▄▃▆"
var values = hashids.decode(hash!); // values:[1,2,3]
```

#### Notes
Internally ```Hashids``` is using integer array rather than strings. 
By default ```Hashids``` class is just a type alias for ```Hashids_<UInt32>``` and is using unicode scalars for all string manipulations. This makes it possible to use unicode alphabets eq. ':hatched_chick::pig::cat::dog::mouse:'.

Generic version ```Hashids_<T>``` can be used for both ASCII and UTF alphabets. Based on how characters are interpreted in Swift there are possible 3 scenarios
* ```Hashids_<UInt8>``` ASCII, uses ```String.UTF8View```
* ```Hashids_<UInt16>``` UTF16, uses ```String.UTF16View```
* ```Hashids_<UInt32>``` Unicode, uses ```String.UnicodeScalarView```


#### License

MIT License. See the `LICENSE` file.
