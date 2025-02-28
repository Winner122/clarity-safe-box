;; SafeBox Contract
;; Secure document storage and access management with encryption support

;; Error codes 
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DOCUMENT_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_KEY (err u103))
(define-constant ERR_INVALID_GROUP (err u104))
(define-constant ERR_EMPTY_MEMBERS (err u105))

;; Data structures
;; [Previous data structures remain unchanged...]

;; Helper functions
(define-private (grant-single-access (member principal) (state (response bool uint)) (doc-hash (buff 32)) (group-key (optional (buff 32))))
  (match state
      success (grant-access doc-hash member group-key)
      failure failure))

;; Public functions
;; [Previous functions remain unchanged until grant-group-access]

;; Grant access to sharing group
(define-public (grant-group-access
    (doc-hash (buff 32))
    (group-id (buff 32))
    (group-key (optional (buff 32))))
    (let
        ((group-data (map-get? sharing-groups {group-id: group-id}))
         (doc-data (map-get? documents {doc-hash: doc-hash})))
        (if (and
                (is-some group-data)
                (is-some doc-data)
                (is-eq tx-sender (get owner (unwrap-panic doc-data))))
            (fold grant-single-access 
                (get members (unwrap-panic group-data))
                (ok true)
                doc-hash
                group-key)
            ERR_NOT_AUTHORIZED
        )
    ))

;; Create sharing group with validation
(define-public (create-sharing-group
    (group-id (buff 32))
    (name (string-ascii 100))
    (members (list 50 principal)))
    (let
        ((existing-group (map-get? sharing-groups {group-id: group-id}))
         (member-count (len members)))
        (if (is-some existing-group)
            ERR_ALREADY_EXISTS
            (if (> member-count u0)
                (begin
                    (map-set sharing-groups
                        {group-id: group-id}
                        {
                            owner: tx-sender,
                            name: name,
                            members: members
                        }
                    )
                    (ok true))
                ERR_EMPTY_MEMBERS))))

;; [Remaining functions unchanged...]
