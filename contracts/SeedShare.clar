;; SeedShare: Heirloom and Rare Seed Exchange Network
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-SEED-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-LISTED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-QUANTITY (err u5))
(define-constant ERR-INVALID-PLANT-TYPE (err u6))
(define-constant ERR-INVALID-GROWING-ZONE (err u7))
(define-constant ERR-INVALID-VARIETY (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))
(define-constant MIN-QUANTITY u10)
(define-data-var next-seed-id uint u1)
(define-map seed-listings
    uint
    {
        grower: principal,
        variety-name: (string-utf8 50),
        description: (string-utf8 200),
        plant-type: (string-utf8 15),
        growing-zone: (string-utf8 10),
        status: (string-utf8 15),
        seed-quantity: uint
    }
)
(define-private (validate-plant-type (plant-type (string-utf8 15)))
    (or 
        (is-eq plant-type u"Vegetable")
        (is-eq plant-type u"Fruit")
        (is-eq plant-type u"Herb")
        (is-eq plant-type u"Flower")
        (is-eq plant-type u"Tree")
        (is-eq plant-type u"Native")
    )
)
(define-private (validate-growing-zone (zone (string-utf8 10)))
    (or 
        (is-eq zone u"Zone 1-3")
        (is-eq zone u"Zone 4-6")
        (is-eq zone u"Zone 7-9")
        (is-eq zone u"Zone 10-13")
        (is-eq zone u"Indoor")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (list-seeds 
    (variety-name (string-utf8 50))
    (description (string-utf8 200))
    (plant-type (string-utf8 15))
    (growing-zone (string-utf8 10))
    (seed-quantity uint)
)
    (let
        (
            (seed-id (var-get next-seed-id))
        )
        (asserts! (validate-text-length variety-name u3 u50) ERR-INVALID-VARIETY)
        (asserts! (validate-text-length description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= seed-quantity MIN-QUANTITY) ERR-INVALID-QUANTITY)
        (asserts! (validate-plant-type plant-type) ERR-INVALID-PLANT-TYPE)
        (asserts! (validate-growing-zone growing-zone) ERR-INVALID-GROWING-ZONE)
        
        (map-set seed-listings seed-id {
            grower: tx-sender,
            variety-name: variety-name,
            description: description,
            plant-type: plant-type,
            growing-zone: growing-zone,
            status: u"available",
            seed-quantity: seed-quantity
        })
        (var-set next-seed-id (+ seed-id u1))
        (ok seed-id)
    )
)
(define-public (delist-seeds (seed-id uint))
    (let
        (
            (listing (unwrap! (map-get? seed-listings seed-id) ERR-SEED-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get grower listing)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status listing) u"available") ERR-INVALID-STATUS)
        (ok (map-set seed-listings seed-id (merge listing { status: u"unavailable" })))
    )
)
(define-read-only (get-seed-listing (seed-id uint))
    (ok (map-get? seed-listings seed-id))
)
(define-read-only (get-grower (seed-id uint))
    (ok (get grower (unwrap! (map-get? seed-listings seed-id) ERR-SEED-NOT-FOUND)))
)
