# Regenerate

<p align="left">
  <a href="https://github.com/pumperknickle/Regenerate/actions?query=workflow%3ABuild"><img alt="GitHub Actions status" src="https://github.com/pumperknickle/Regenerate/workflows/Build/badge.svg"></a>
</p>

  
## Installation
### Swift Package Manager

Add Regenerate to Package.swift and the appropriate targets
```swift
dependencies: [
.package(url: "https://github.com/pumperknickle/Regenerate.git", from: "1.0.0")
]
```

## Conceptual Overview

Regenerate empowers users to creating custom authenticated data structures in a declarative manner similar to how structs or classes are defined.

The intuition here is that with authenticated data structures, if you and I agree on a hash digest, then we also agree on all the data hashed by that hash digest. Since you can hash a hash digest, this agreement operates recursively.

An example of a cryptographic data structure is a merkle tree (used by bitcoin, github) or patricia merkle trie (used by Ethereum).
