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

Regenerate is a framework for creating, encrypting, and regenerating cryptographic data structures or CDS for short. A CDS has integrity guarantees. Each CDS has a root digest, which can be a considered a reference or address to the data structure as a whole.

Given the digest of a particaular CDS, one is guaranteed to regenerate the same structure bit for bit. A cryptographic data structure can also be pieced into its base nodes - these pieces can be used to regenerate the structure. The CDS digest, the structure data type, and the node pieces are enough to regenerate the full structure.

An example of a cryptographic data structure is a merkle tree (used by bitcoin, github) or patricia merkle trie (used by Ethereum).
