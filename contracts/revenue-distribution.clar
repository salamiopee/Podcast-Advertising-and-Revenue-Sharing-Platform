;; Revenue Distribution Contract
;; Manages automated revenue sharing between stakeholders

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-INPUT (err u401))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-DISTRIBUTION-NOT-FOUND (err u403))
(define-constant ERR-ALREADY-CLAIMED (err u404))

;; Data Variables
(define-data-var next-distribution-id uint u1)
(define-data-var platform-fee-percentage uint u10) ;; 10% platform fee
(define-data-var podcaster-share-percentage uint u70) ;; 70% to podcaster
(define-data-var advertiser-refund-percentage uint u20) ;; 20% back to advertiser

;; Data Maps
(define-map revenue-distributions
  { distribution-id: uint }
  {
    podcast-id: uint,
    campaign-id: uint,
    total-revenue: uint,
    platform-fee: uint,
    podcaster-share: uint,
    advertiser-refund: uint,
    created-at: uint,
    distributed: bool
  }
)

(define-map pending-payments
  { recipient: principal, distribution-id: uint }
  {
    amount: uint,
    claimed: bool,
    payment-type: (string-ascii 20) ;; "podcaster", "platform", "advertiser"
  }
)

(define-map total-earnings
  { recipient: principal }
  {
    total-earned: uint,
    total-claimed: uint,
    payment-count: uint
  }
)

(define-map monthly-revenue
  { month: uint, podcast-id: uint }
  { revenue: uint }
)

;; Public Functions

;; Create revenue distribution
(define-public (create-distribution (podcast-id uint) (campaign-id uint) (total-revenue uint))
  (let
    (
      (distribution-id (var-get next-distribution-id))
      (platform-fee (/ (* total-revenue (var-get platform-fee-percentage)) u100))
      (podcaster-share (/ (* total-revenue (var-get podcaster-share-percentage)) u100))
      (advertiser-refund (/ (* total-revenue (var-get advertiser-refund-percentage)) u100))
      (current-month (/ block-height u4320)) ;; Approximate monthly blocks
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> total-revenue u0) ERR-INVALID-INPUT)

    ;; Create distribution record
    (map-set revenue-distributions
      { distribution-id: distribution-id }
      {
        podcast-id: podcast-id,
        campaign-id: campaign-id,
        total-revenue: total-revenue,
        platform-fee: platform-fee,
        podcaster-share: podcaster-share,
        advertiser-refund: advertiser-refund,
        created-at: block-height,
        distributed: false
      }
    )

    ;; Update monthly revenue
    (map-set monthly-revenue
      { month: current-month, podcast-id: podcast-id }
      { revenue: (+ (get-monthly-revenue current-month podcast-id) total-revenue) }
    )

    ;; Increment next distribution ID
    (var-set next-distribution-id (+ distribution-id u1))

    (ok distribution-id)
  )
)

;; Distribute payments to stakeholders
(define-public (distribute-payments (distribution-id uint) (podcast-owner principal) (advertiser principal))
  (let
    (
      (distribution (unwrap! (map-get? revenue-distributions { distribution-id: distribution-id }) ERR-DISTRIBUTION-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (get distributed distribution)) ERR-ALREADY-CLAIMED)

    ;; Create pending payments for podcaster
    (map-set pending-payments
      { recipient: podcast-owner, distribution-id: distribution-id }
      {
        amount: (get podcaster-share distribution),
        claimed: false,
        payment-type: "podcaster"
      }
    )

    ;; Create pending payments for advertiser refund
    (map-set pending-payments
      { recipient: advertiser, distribution-id: distribution-id }
      {
        amount: (get advertiser-refund distribution),
        claimed: false,
        payment-type: "advertiser"
      }
    )

    ;; Create pending payments for platform
    (map-set pending-payments
      { recipient: CONTRACT-OWNER, distribution-id: distribution-id }
      {
        amount: (get platform-fee distribution),
        claimed: false,
        payment-type: "platform"
      }
    )

    ;; Mark as distributed
    (map-set revenue-distributions
      { distribution-id: distribution-id }
      (merge distribution { distributed: true })
    )

    (ok true)
  )
)

;; Claim pending payment
(define-public (claim-payment (distribution-id uint))
  (let
    (
      (payment (unwrap! (map-get? pending-payments { recipient: tx-sender, distribution-id: distribution-id }) ERR-DISTRIBUTION-NOT-FOUND))
      (current-earnings (get-total-earnings tx-sender))
    )
    (asserts! (not (get claimed payment)) ERR-ALREADY-CLAIMED)
    (asserts! (> (get amount payment) u0) ERR-INVALID-INPUT)

    ;; Transfer payment
    (try! (as-contract (stx-transfer? (get amount payment) tx-sender tx-sender)))

    ;; Mark as claimed
    (map-set pending-payments
      { recipient: tx-sender, distribution-id: distribution-id }
      (merge payment { claimed: true })
    )

    ;; Update total earnings
    (map-set total-earnings
      { recipient: tx-sender }
      {
        total-earned: (+ (get total-earned current-earnings) (get amount payment)),
        total-claimed: (+ (get total-claimed current-earnings) (get amount payment)),
        payment-count: (+ (get payment-count current-earnings) u1)
      }
    )

    (ok true)
  )
)

;; Update revenue sharing percentages (contract owner only)
(define-public (update-revenue-shares (platform-fee uint) (podcaster-share uint) (advertiser-refund uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (+ platform-fee podcaster-share advertiser-refund) u100) ERR-INVALID-INPUT)

    (var-set platform-fee-percentage platform-fee)
    (var-set podcaster-share-percentage podcaster-share)
    (var-set advertiser-refund-percentage advertiser-refund)

    (ok true)
  )
)

;; Emergency withdraw (contract owner only)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-INPUT)

    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))

    (ok true)
  )
)

;; Read-only Functions

;; Get distribution details
(define-read-only (get-distribution (distribution-id uint))
  (map-get? revenue-distributions { distribution-id: distribution-id })
)

;; Get pending payment
(define-read-only (get-pending-payment (recipient principal) (distribution-id uint))
  (map-get? pending-payments { recipient: recipient, distribution-id: distribution-id })
)

;; Get total earnings for recipient
(define-read-only (get-total-earnings (recipient principal))
  (default-to
    { total-earned: u0, total-claimed: u0, payment-count: u0 }
    (map-get? total-earnings { recipient: recipient })
  )
)

;; Get monthly revenue for podcast
(define-read-only (get-monthly-revenue (month uint) (podcast-id uint))
  (default-to u0 (get revenue (map-get? monthly-revenue { month: month, podcast-id: podcast-id })))
)

;; Get revenue sharing percentages
(define-read-only (get-revenue-shares)
  {
    platform-fee: (var-get platform-fee-percentage),
    podcaster-share: (var-get podcaster-share-percentage),
    advertiser-refund: (var-get advertiser-refund-percentage)
  }
)

;; Get next distribution ID
(define-read-only (get-next-distribution-id)
  (var-get next-distribution-id)
)

;; Calculate total unclaimed payments for recipient
(define-read-only (get-unclaimed-amount (recipient principal))
  (let
    (
      (earnings (get-total-earnings recipient))
    )
    (- (get total-earned earnings) (get total-claimed earnings))
  )
)

;; Get contract balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)
