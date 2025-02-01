;; SafeBox Contract
;; Secure document storage and access management with encryption support

;; Error codes 
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DOCUMENT_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_KEY (err u103))

;; Data structures
(define-map documents
    { doc-hash: (buff 32) }
    {
        owner: principal,
        name: (string-ascii 100),
        timestamp: uint,
        description: (string-ascii 500),
        encryption-key: (optional (buff 32)),
        encrypted: bool
    }
)

(define-map access-rights
    { doc-hash: (buff 32), user: principal }
    { 
        can-access: bool,
        user-key: (optional (buff 32))
    }
)

(define-map document-history
    { doc-hash: (buff 32), version: uint }
    {
        previous-hash: (optional (buff 32)),
        timestamp: uint,
        modified-by: principal,
        encryption-updated: bool
    }
)

(define-map sharing-groups
    { group-id: (buff 32) }
    {
        owner: principal,
        name: (string-ascii 100),
        members: (list 50 principal)
    }
)

;; Public functions

;; Register a new document with optional encryption
(define-public (register-document 
    (doc-hash (buff 32))
    (name (string-ascii 100))
    (description (string-ascii 500))
    (encryption-key (optional (buff 32))))
    (let
        ((existing-doc (get owner (map-get? documents {doc-hash: doc-hash}))))
        (if (is-some existing-doc)
            ERR_ALREADY_EXISTS
            (begin
                (map-set documents
                    {doc-hash: doc-hash}
                    {
                        owner: tx-sender,
                        name: name,
                        timestamp: block-height,
                        description: description,
                        encryption-key: encryption-key,
                        encrypted: (is-some encryption-key)
                    }
                )
                (map-set access-rights
                    {doc-hash: doc-hash, user: tx-sender}
                    {can-access: true, user-key: encryption-key}
                )
                (ok true)
            )
        )
    )
)

;; Grant access to a user with optional encryption key
(define-public (grant-access 
    (doc-hash (buff 32)) 
    (user principal)
    (user-key (optional (buff 32))))
    (let
        ((doc-data (map-get? documents {doc-hash: doc-hash})))
        (if (and
                (is-some doc-data)
                (is-eq tx-sender (get owner (unwrap-panic doc-data))))
            (begin
                (map-set access-rights
                    {doc-hash: doc-hash, user: user}
                    {can-access: true, user-key: user-key}
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Create sharing group
(define-public (create-sharing-group
    (group-id (buff 32))
    (name (string-ascii 100))
    (members (list 50 principal)))
    (begin
        (map-set sharing-groups
            {group-id: group-id}
            {
                owner: tx-sender,
                name: name,
                members: members
            }
        )
        (ok true)
    )
)

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
            (begin
                (map grant-access 
                    (unwrap-panic (get members (unwrap-panic group-data)))
                    doc-hash
                    group-key)
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Update encryption key
(define-public (update-encryption
    (doc-hash (buff 32))
    (new-key (optional (buff 32))))
    (let
        ((doc-data (map-get? documents {doc-hash: doc-hash})))
        (if (and
                (is-some doc-data)
                (is-eq tx-sender (get owner (unwrap-panic doc-data))))
            (begin
                (map-set documents
                    {doc-hash: doc-hash}
                    (merge (unwrap-panic doc-data)
                        {
                            encryption-key: new-key,
                            encrypted: (is-some new-key)
                        }
                    )
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Other existing functions remain unchanged...
