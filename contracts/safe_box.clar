;; SafeBox Contract
;; Secure document storage and access management with encryption support

;; Error codes 
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DOCUMENT_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_KEY (err u103))
(define-constant ERR_INVALID_GROUP (err u104))
(define-constant ERR_EMPTY_MEMBERS (err u105))
(define-constant ERR_ALREADY_HAS_ACCESS (err u106))
(define-constant ERR_INVALID_ENCRYPTION_STATE (err u107))

;; Helper functions
(define-private (has-access (doc-hash (buff 32)) (member principal))
  (default-to false (get-in-map? document-access {doc-hash: doc-hash, user: member} {has-access: true})))

(define-private (validate-encryption-state (doc-data (optional {owner: principal, name: (string-ascii 100), description: (string-ascii 500), encryption-key: (optional (buff 32))})) (group-key (optional (buff 32))))
  (match doc-data
    doc-info (is-eq (is-some (get encryption-key doc-info)) (is-some group-key))
    false))

(define-private (grant-single-access (member principal) (state (response bool uint)) (doc-hash (buff 32)) (group-key (optional (buff 32))))
  (match state
    success (if (has-access doc-hash member)
               (err ERR_ALREADY_HAS_ACCESS)
               (grant-access doc-hash member group-key))
    failure failure))

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
                (is-eq tx-sender (get owner (unwrap-panic doc-data)))
                (validate-encryption-state doc-data group-key))
            (fold grant-single-access 
                (get members (unwrap-panic group-data))
                (ok true)
                doc-hash
                group-key)
            ERR_NOT_AUTHORIZED
        )))

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
