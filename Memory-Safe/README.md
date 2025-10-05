# MemoryVault - Blockchain-Based Time-Locked Digital Memory Storage System Contract

A decentralized blockchain-based time-locked digital memory storage system built on the Stacks blockchain.

## Overview

MemoryVault allows users to create immutable, time-locked digital memory capsules that automatically become accessible after a specified time period. The system supports both private and public capsules with flexible access controls, designated viewers, and public discovery features.

## Core Features

### Time-Locked Storage
- Create memory capsules that unlock after a specified number of blocks
- Configurable lock duration within system-defined minimum and maximum limits
- Automatic unlocking based on blockchain height

### Privacy Controls
- Private capsules accessible only to creator and designated viewers
- Public capsules discoverable by anyone after unlock
- Access tracking for monitoring capsule opens

### Designated Viewers
- Optionally specify a viewer who can access private capsules after unlock
- Useful for messages intended for specific recipients
- Creator maintains full control alongside viewer access

### Discovery System
- Random discovery of public unlocked capsules
- Pseudo-random algorithm with multiple search attempts
- Encourages serendipitous discovery of memories

### Rich Metadata
- Title and detailed description for each capsule
- Content type specification
- Creation timestamp tracking
- Content hash for external data reference

## Smart Contract Functions

### Public Functions

#### create-capsule
Creates a new time-locked memory capsule with metadata.

**Parameters:**
- `hash` (string-ascii 256): Content hash or reference
- `capsule-title` (string-ascii 256): Display title
- `capsule-description` (string-ascii 1024): Detailed description
- `type-of-content` (string-ascii 64): Content format type
- `lock-duration` (uint): Number of blocks until unlock
- `private-mode` (bool): Whether capsule is private
- `designated-viewer` (principal): Address of designated viewer
- `has-designated-viewer-flag` (bool): Whether a viewer is set

**Returns:** Capsule ID on success

**Validations:**
- Lock duration must be within configured min/max limits
- All text fields must be non-empty
- Designated viewer must be valid if set
- User must not exceed capsule storage limit

#### open-capsule
Unlocks and accesses a capsule if the time lock has expired.

**Parameters:**
- `capsule-id` (uint): ID of capsule to open

**Returns:** Success boolean

**Access Control:**
- Public capsules: Accessible by anyone after unlock
- Private capsules: Accessible by creator or designated viewer only
- Tracks access by non-creators

#### disable-capsule
Deactivates a capsule, making it inaccessible.

**Parameters:**
- `capsule-id` (uint): ID of capsule to disable

**Returns:** Success boolean

**Restrictions:** Creator only

#### clear-access-log
Resets the access history for a capsule.

**Parameters:**
- `capsule-id` (uint): ID of capsule to reset

**Returns:** Success boolean

**Restrictions:** Creator only

#### find-random-capsule
Discovers a random public unlocked capsule.

**Returns:** Capsule ID on success

**Algorithm:** Uses pseudo-random search with five attempts to find discoverable capsules

### Read-Only Functions

#### get-full-capsule-info
Retrieves complete capsule data and metadata.

**Parameters:**
- `capsule-id` (uint): ID of capsule to retrieve

**Returns:** Object containing capsule data and metadata

**Access Control:** Same as open-capsule

#### get-lock-status
Returns lock status and remaining blocks until unlock.

**Parameters:**
- `capsule-id` (uint): ID of capsule to check

**Returns:** Object with unlock status and remaining blocks

#### get-user-capsules
Returns list of all capsule IDs owned by a user.

**Parameters:**
- `user` (principal): User address to query

**Returns:** List of capsule IDs

#### get-capsule-count
Returns the total number of capsules created in the system.

#### get-system-config
Returns all system configuration parameters including min/max lock duration and user limits.

### Administrative Functions

#### set-min-lock-duration
Updates minimum allowed lock duration.

**Restrictions:** Contract administrator only

#### set-max-lock-duration
Updates maximum allowed lock duration.

**Restrictions:** Contract administrator only

#### set-user-limit
Updates maximum capsules allowed per user.

**Restrictions:** Contract administrator only

#### configure-system
Updates all system parameters atomically.

**Restrictions:** Contract administrator only

## System Configuration

### Default Parameters
- Minimum lock blocks: 1
- Maximum lock blocks: 52,560 (approximately 1 year assuming 10-minute blocks)
- User capsule limit: 127

### Capsule Limits
Users can create up to 127 capsules (configurable by administrator).

## Data Structures

### Capsule Core Data
- Creator address
- Content hash fingerprint
- Unlock block height
- Privacy status
- Access tracking
- Designated viewer information
- Active status

### Capsule Metadata
- Display title
- Detailed description
- Content format type
- Creation block height

## Error Codes

- `u100` - Owner/Admin only operation
- `u101` - Capsule already unlocked
- `u102` - Capsule still locked
- `u103` - Capsule not found
- `u104` - Unauthorized access
- `u105` - Invalid parameters
- `u106` - Not capsule creator
- `u107` - No public capsules available
- `u108` - Storage limit exceeded
- `u109` - Empty required field
- `u110` - Invalid viewer address
- `u111` - Invalid value

## Use Cases

### Personal Time Capsules
Create messages to your future self that unlock after a specified period.

### Scheduled Messages
Send messages to others that become accessible at a predetermined time.

### Public Memory Sharing
Create publicly discoverable memories that others can find and read after unlock.

### Long-term Archival
Store references to content with guaranteed future accessibility.

## Technical Details

### Blockchain Platform
Built on Stacks blockchain using Clarity smart contract language.

### Storage Model
- On-chain metadata and access control
- Content hash references for off-chain storage
- Efficient data structures optimized for blockchain storage

### Random Number Generation
Pseudo-random algorithm using block height and internal seed for discovery functionality.

## Security Considerations

- Immutable storage: Capsules cannot be modified after creation
- Time-based access: Enforced by blockchain height
- Privacy controls: Cryptographically enforced access restrictions
- Content references: Actual content stored off-chain for efficiency and privacy