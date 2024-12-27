;; SafeBox Contract
;; Secure document storage and access management

;; Error codes
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DOCUMENT_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))

;; Data structures
(define-map documents
    { doc-hash: (buff 32) }
    {
        owner: principal,
        name: (string-ascii 100),
        timestamp: uint,
        description: (string-ascii 500)
    }
)

(define-map access-rights
    { doc-hash: (buff 32), user: principal }
    { can-access: bool }
)

(define-map document-history
    { doc-hash: (buff 32), version: uint }
    {
        previous-hash: (optional (buff 32)),
        timestamp: uint,
        modified-by: principal
    }
)

;; Public functions

;; Register a new document
(define-public (register-document 
    (doc-hash (buff 32))
    (name (string-ascii 100))
    (description (string-ascii 500)))
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
                        description: description
                    }
                )
                (map-set access-rights
                    {doc-hash: doc-hash, user: tx-sender}
                    {can-access: true}
                )
                (ok true)
            )
        )
    )
)

;; Grant access to a user
(define-public (grant-access (doc-hash (buff 32)) (user principal))
    (let
        ((doc-data (map-get? documents {doc-hash: doc-hash})))
        (if (and
                (is-some doc-data)
                (is-eq tx-sender (get owner (unwrap-panic doc-data))))
            (begin
                (map-set access-rights
                    {doc-hash: doc-hash, user: user}
                    {can-access: true}
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Revoke access from a user
(define-public (revoke-access (doc-hash (buff 32)) (user principal))
    (let
        ((doc-data (map-get? documents {doc-hash: doc-hash})))
        (if (and
                (is-some doc-data)
                (is-eq tx-sender (get owner (unwrap-panic doc-data))))
            (begin
                (map-set access-rights
                    {doc-hash: doc-hash, user: user}
                    {can-access: false}
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Update document (register new version)
(define-public (update-document 
    (old-hash (buff 32))
    (new-hash (buff 32))
    (name (string-ascii 100))
    (description (string-ascii 500)))
    (let
        ((doc-data (map-get? documents {doc-hash: old-hash}))
         (version (get-document-version old-hash)))
        (if (and
                (is-some doc-data)
                (is-eq tx-sender (get owner (unwrap-panic doc-data))))
            (begin
                (try! (register-document new-hash name description))
                (map-set document-history
                    {doc-hash: new-hash, version: (+ version u1)}
                    {
                        previous-hash: (some old-hash),
                        timestamp: block-height,
                        modified-by: tx-sender
                    }
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Read only functions

;; Check if user has access to document
(define-read-only (has-access (doc-hash (buff 32)) (user principal))
    (default-to
        false
        (get can-access (map-get? access-rights {doc-hash: doc-hash, user: user}))
    )
)

;; Get document metadata
(define-read-only (get-document (doc-hash (buff 32)))
    (let
        ((doc-data (map-get? documents {doc-hash: doc-hash})))
        (if (and
                (is-some doc-data)
                (has-access doc-hash tx-sender))
            (ok (unwrap-panic doc-data))
            ERR_DOCUMENT_NOT_FOUND
        )
    )
)

;; Get document version
(define-read-only (get-document-version (doc-hash (buff 32)))
    (default-to
        u0
        (fold - (map-get? document-history {doc-hash: doc-hash, version: u1}))
    )
)