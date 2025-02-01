# SafeBox
A secure blockchain-based platform for storing sensitive document hashes and managing access control. Documents are referenced by their hash values while actual content remains off-chain. The contract provides secure document registration, access management, and verification capabilities.

## Features
- Register document hashes with metadata
- Grant/revoke access to specific users
- Verify document authenticity using hash values
- Track document history and modifications
- **Document Encryption Support**
  - Register documents with encryption keys
  - Manage encrypted access for users
  - Update encryption keys
- **Sharing Groups**
  - Create and manage sharing groups
  - Grant access to multiple users simultaneously
  - Separate encryption keys for different groups

## Encryption Support
The platform now supports document encryption with the following capabilities:
- Register documents with optional encryption keys
- Grant access to users with unique encryption keys
- Update document encryption keys
- Track encryption changes in document history

## Sharing Groups
Sharing groups provide efficient access management:
- Create named groups with multiple members
- Grant access to entire groups at once
- Manage group-specific encryption keys
- Flexible group membership management
