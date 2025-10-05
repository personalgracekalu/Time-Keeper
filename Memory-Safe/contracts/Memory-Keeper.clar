;; MemoryVault - Blockchain-Based Time-Locked Digital Memory Storage System Contract
;; A decentralized platform for creating immutable, time-locked digital memories on the Stacks blockchain
;; Users can store encrypted content references that automatically become accessible after a specified time period
;; Features include private/public capsules, designated viewers, discovery of public memories, and flexible access controls

(define-constant contract-administrator tx-sender)

;; Error codes for operation failures
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-ALREADY-UNLOCKED (err u101))
(define-constant ERR-STILL-LOCKED (err u102))
(define-constant ERR-NOT-FOUND (err u103))
(define-constant ERR-UNAUTHORIZED-ACCESS (err u104))
(define-constant ERR-INVALID-PARAMETERS (err u105))
(define-constant ERR-NOT-CREATOR (err u106))
(define-constant ERR-NO-PUBLIC-CAPSULES (err u107))
(define-constant ERR-STORAGE-LIMIT-EXCEEDED (err u108))
(define-constant ERR-EMPTY-FIELD (err u109))
(define-constant ERR-INVALID-VIEWER (err u110))
(define-constant ERR-INVALID-VALUE (err u111))

;; Configurable system parameters for production flexibility
(define-data-var min-lock-blocks uint u1)
(define-data-var max-lock-blocks uint u52560)
(define-data-var user-capsule-limit uint u127)

;; Global tracking state
(define-data-var capsule-counter uint u0)
(define-data-var random-seed uint u1)

;; Core capsule data storage
(define-map capsule-owner uint principal)
(define-map content-hash uint (string-ascii 256))
(define-map unlock-height uint uint)
(define-map is-private uint bool)
(define-map was-accessed uint bool)
(define-map viewer-address uint principal)
(define-map has-viewer uint bool)
(define-map is-active uint bool)

;; Metadata storage for capsules
(define-map title uint (string-ascii 256))
(define-map description uint (string-ascii 1024))
(define-map content-type uint (string-ascii 64))
(define-map created-at uint uint)

;; User capsule inventory tracking
(define-map user-capsules principal (list 127 uint))

;; Adds a capsule ID to a user's collection with limit enforcement
(define-private (add-to-user-collection (owner principal) (capsule-id uint))
  (let ((current-list (default-to (list) (map-get? user-capsules owner)))
        (max-allowed (var-get user-capsule-limit)))
    (if (>= (len current-list) max-allowed)
      false
      (begin
        (map-set user-capsules owner 
                 (unwrap! (as-max-len? (append current-list capsule-id) u127) false))
        true))))

;; Generates pseudo-random numbers for discovery functionality
(define-private (get-random-number)
  (let ((current-seed (var-get random-seed)))
    (var-set random-seed (+ (* current-seed u37) (+ block-height u17)))
    (var-get random-seed)))

;; Checks if a capsule is eligible for public discovery
(define-private (can-be-discovered (capsule-id uint))
  (let ((active (default-to false (map-get? is-active capsule-id)))
        (unlock-at (default-to u0 (map-get? unlock-height capsule-id)))
        (private (default-to true (map-get? is-private capsule-id))))
    (and active
         (>= block-height unlock-at)
         (not private))))

;; Constructs the core data structure for a capsule
(define-private (build-capsule-data (capsule-id uint))
  {
    creator-address: (default-to tx-sender (map-get? capsule-owner capsule-id)),
    content-hash-fingerprint: (default-to "" (map-get? content-hash capsule-id)),
    unlock-at-block-height: (default-to u0 (map-get? unlock-height capsule-id)),
    is-private-capsule: (default-to false (map-get? is-private capsule-id)),
    has-been-accessed: (default-to false (map-get? was-accessed capsule-id)),
    designated-viewer-address: (default-to tx-sender (map-get? viewer-address capsule-id)),
    has-designated-viewer-set: (default-to false (map-get? has-viewer capsule-id)),
    is-active-capsule: (default-to false (map-get? is-active capsule-id))
  })

;; Constructs the metadata structure for a capsule
(define-private (build-metadata (capsule-id uint))
  {
    display-title: (default-to "" (map-get? title capsule-id)),
    detailed-description: (default-to "" (map-get? description capsule-id)),
    content-format-type: (default-to "" (map-get? content-type capsule-id)),
    created-at-block-height: (default-to u0 (map-get? created-at capsule-id))
  })

;; Validates that a string field is not empty
(define-private (is-not-empty (text (string-ascii 1024)))
  (not (is-eq text "")))

;; Validates designated viewer address when set
(define-private (is-valid-viewer (viewer principal) (has-designated-viewer bool))
  (if has-designated-viewer
    (not (is-eq viewer 'SP000000000000000000002Q6VF78))
    true))

;; Creates a new time-locked memory capsule with all metadata
(define-public (create-capsule 
              (hash (string-ascii 256)) 
              (capsule-title (string-ascii 256))
              (capsule-description (string-ascii 1024))
              (type-of-content (string-ascii 64))
              (lock-duration uint)
              (private-mode bool)
              (designated-viewer principal)
              (has-designated-viewer-flag bool))
  (begin
    ;; Validate lock duration against system constraints
    (asserts! (and (>= lock-duration (var-get min-lock-blocks)) 
                  (<= lock-duration (var-get max-lock-blocks))) 
              ERR-INVALID-PARAMETERS)
    
    ;; Ensure all required fields contain data
    (asserts! (is-not-empty hash) ERR-EMPTY-FIELD)
    (asserts! (is-not-empty capsule-title) ERR-EMPTY-FIELD)
    (asserts! (is-not-empty capsule-description) ERR-EMPTY-FIELD)
    (asserts! (is-not-empty type-of-content) ERR-EMPTY-FIELD)
    
    ;; Validate viewer configuration
    (asserts! (is-valid-viewer designated-viewer has-designated-viewer-flag) 
              ERR-INVALID-VIEWER)
    
    (let ((new-id (var-get capsule-counter))
          (unlock-at (+ block-height lock-duration)))
      
      ;; Store core capsule properties
      (map-set capsule-owner new-id tx-sender)
      (map-set content-hash new-id hash)
      (map-set unlock-height new-id unlock-at)
      (map-set is-private new-id private-mode)
      (map-set was-accessed new-id false)
      (map-set viewer-address new-id designated-viewer)
      (map-set has-viewer new-id has-designated-viewer-flag)
      (map-set is-active new-id true)
      
      ;; Store metadata
      (map-set title new-id capsule-title)
      (map-set description new-id capsule-description)
      (map-set content-type new-id type-of-content)
      (map-set created-at new-id block-height)
      
      ;; Add to user's collection with limit check
      (asserts! (add-to-user-collection tx-sender new-id) 
                ERR-STORAGE-LIMIT-EXCEEDED)
      
      ;; Increment counter and return new ID
      (var-set capsule-counter (+ new-id u1))
      (ok new-id))))

;; Unlocks a capsule if time lock has expired and caller has permission
(define-public (open-capsule (capsule-id uint))
  (let ((active (default-to false (map-get? is-active capsule-id)))
        (unlock-at (default-to u0 (map-get? unlock-height capsule-id)))
        (private (default-to false (map-get? is-private capsule-id)))
        (owner (default-to tx-sender (map-get? capsule-owner capsule-id)))
        (has-designated-viewer (default-to false (map-get? has-viewer capsule-id)))
        (designated-viewer (default-to tx-sender (map-get? viewer-address capsule-id))))
    
    ;; Verify capsule exists and is active
    (asserts! active ERR-NOT-FOUND)
    
    ;; Check if time lock has expired
    (asserts! (>= block-height unlock-at) ERR-STILL-LOCKED)
    
    ;; Handle private capsule access control
    (if private
      (begin
        ;; Verify caller is authorized
        (asserts! (or
            (is-eq tx-sender owner)
            (and has-designated-viewer
                 (is-eq tx-sender designated-viewer)))
            ERR-UNAUTHORIZED-ACCESS)
        
        ;; Track access by non-owners
        (if (not (is-eq tx-sender owner))
          (map-set was-accessed capsule-id true)
          true)
        (ok true))
      
      ;; Public capsule - allow access and track
      (begin
        (map-set was-accessed capsule-id true)
        (ok true)))))

;; Deactivates a capsule (creator only)
(define-public (disable-capsule (capsule-id uint))
  (let ((owner (default-to tx-sender (map-get? capsule-owner capsule-id))))
    ;; Verify caller is creator
    (asserts! (is-eq tx-sender owner) ERR-NOT-CREATOR)
    
    ;; Mark as inactive
    (map-set is-active capsule-id false)
    (ok true)))

;; Resets access history for a capsule (creator only)
(define-public (clear-access-log (capsule-id uint))
  (let ((owner (default-to tx-sender (map-get? capsule-owner capsule-id))))
    ;; Verify caller is creator
    (asserts! (is-eq tx-sender owner) ERR-NOT-CREATOR)
    
    ;; Reset access flag
    (map-set was-accessed capsule-id false)
    (ok true)))

;; Returns capsule data if it's discoverable
(define-read-only (check-if-discoverable (capsule-id uint))
  (if (can-be-discovered capsule-id)
    (some (build-capsule-data capsule-id))
    none))

;; Attempts to find a discoverable capsule at a given search position
(define-private (try-find-capsule (search-offset uint))
  (let ((random-value (get-random-number))
        (target-id (mod (+ random-value search-offset) (var-get capsule-counter))))
    (if (can-be-discovered target-id)
      target-id
      u0)))

;; Discovers a random public unlocked capsule through multiple search attempts
(define-public (find-random-capsule)
  (let ((total (var-get capsule-counter)))
    ;; Ensure capsules exist
    (asserts! (> total u0) ERR-NOT-FOUND)
    
    ;; Try five different search positions
    (let ((try-1 (try-find-capsule u0))
          (try-2 (try-find-capsule u1))
          (try-3 (try-find-capsule u2))
          (try-4 (try-find-capsule u3))
          (try-5 (try-find-capsule u4)))
      
      ;; Return first successful find
      (if (> try-1 u0)
        (ok try-1)
        (if (> try-2 u0)
          (ok try-2)
          (if (> try-3 u0)
            (ok try-3)
            (if (> try-4 u0)
              (ok try-4)
              (if (> try-5 u0)
                (ok try-5)
                ERR-NO-PUBLIC-CAPSULES))))))))

;; Retrieves complete capsule information if accessible to caller
(define-read-only (get-full-capsule-info (capsule-id uint))
  (let ((active (default-to false (map-get? is-active capsule-id)))
        (unlock-at (default-to u0 (map-get? unlock-height capsule-id)))
        (private (default-to false (map-get? is-private capsule-id)))
        (owner (default-to tx-sender (map-get? capsule-owner capsule-id)))
        (has-designated-viewer (default-to false (map-get? has-viewer capsule-id)))
        (designated-viewer (default-to tx-sender (map-get? viewer-address capsule-id))))
    
    ;; Verify capsule exists and is active
    (asserts! active ERR-NOT-FOUND)
    
    ;; Check if unlocked
    (asserts! (>= block-height unlock-at) ERR-STILL-LOCKED)
    
    ;; Apply access control for private capsules
    (if private
      (if (or
          (is-eq tx-sender owner)
          (and has-designated-viewer
               (is-eq tx-sender designated-viewer)))
          (ok {
            record-data: (build-capsule-data capsule-id),
            metadata-info: (build-metadata capsule-id)
          })
          ERR-UNAUTHORIZED-ACCESS)
      
      ;; Return data for public capsules
      (ok {
        record-data: (build-capsule-data capsule-id),
        metadata-info: (build-metadata capsule-id)
      }))))

;; Returns the total number of capsules created
(define-read-only (get-capsule-count)
  (ok (var-get capsule-counter)))

;; Returns lock status and remaining blocks until unlock
(define-read-only (get-lock-status (capsule-id uint))
  (let ((active (default-to false (map-get? is-active capsule-id)))
        (unlock-at (default-to u0 (map-get? unlock-height capsule-id))))
    
    (if active
      (ok {
        is-unlocked: (>= block-height unlock-at),
        blocks-until-unlock: (if (>= block-height unlock-at)
                            u0
                            (- unlock-at block-height))
      })
      ERR-NOT-FOUND)))

;; Returns list of all capsule IDs owned by a user
(define-read-only (get-user-capsules (user principal))
  (ok (default-to (list) (map-get? user-capsules user))))

;; Returns minimum allowed lock duration
(define-read-only (get-min-lock-duration)
  (ok (var-get min-lock-blocks)))

;; Returns maximum allowed lock duration
(define-read-only (get-max-lock-duration)
  (ok (var-get max-lock-blocks)))

;; Returns maximum capsules allowed per user
(define-read-only (get-user-limit)
  (ok (var-get user-capsule-limit)))

;; Returns all system configuration parameters
(define-read-only (get-system-config)
  (ok {
    minimum-lock-duration: (var-get min-lock-blocks),
    maximum-lock-duration: (var-get max-lock-blocks),
    maximum-capsules-per-user: (var-get user-capsule-limit)
  }))

;; Updates minimum lock duration (admin only)
(define-public (set-min-lock-duration (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-OWNER-ONLY)
    (asserts! (> new-minimum u0) ERR-INVALID-VALUE)
    (asserts! (<= new-minimum (var-get max-lock-blocks)) ERR-INVALID-VALUE)
    (var-set min-lock-blocks new-minimum)
    (ok true)))

;; Updates maximum lock duration (admin only)
(define-public (set-max-lock-duration (new-maximum uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-OWNER-ONLY)
    (asserts! (>= new-maximum (var-get min-lock-blocks)) ERR-INVALID-VALUE)
    (asserts! (> new-maximum u0) ERR-INVALID-VALUE)
    (var-set max-lock-blocks new-maximum)
    (ok true)))

;; Updates maximum capsules per user (admin only)
(define-public (set-user-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-OWNER-ONLY)
    (asserts! (and (> new-limit u0) (<= new-limit u127)) ERR-INVALID-VALUE)
    (var-set user-capsule-limit new-limit)
    (ok true)))

;; Updates all system parameters atomically (admin only)
(define-public (configure-system (new-min uint) (new-max uint) (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-OWNER-ONLY)
    
    ;; Validate all parameters before applying changes
    (asserts! (> new-min u0) ERR-INVALID-VALUE)
    (asserts! (> new-max u0) ERR-INVALID-VALUE)
    (asserts! (<= new-min new-max) ERR-INVALID-VALUE)
    (asserts! (and (> new-limit u0) (<= new-limit u127)) ERR-INVALID-VALUE)
    
    ;; Apply all changes together
    (var-set min-lock-blocks new-min)
    (var-set max-lock-blocks new-max)
    (var-set user-capsule-limit new-limit)
    (ok true)))