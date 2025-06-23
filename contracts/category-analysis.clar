;; Category Analysis Contract
;; Analyzes spend by category and provides insights

(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u300))
(define-constant err-not-found (err u301))
(define-constant err-invalid-params (err u302))

;; Data structures
(define-map category-analysis
  { category: (string-ascii 50), period: uint }
  {
    total-spend: uint,
    transaction-count: uint,
    average-transaction: uint,
    top-supplier: (string-ascii 100),
    trend-direction: (string-ascii 10),
    analysis-date: uint
  }
)

(define-map category-benchmarks
  { category: (string-ascii 50) }
  {
    benchmark-spend: uint,
    target-savings: uint,
    performance-score: uint
  }
)

(define-map supplier-category-spend
  { supplier: (string-ascii 100), category: (string-ascii 50) }
  { total-spend: uint, transaction-count: uint }
)

;; Read-only functions
(define-read-only (get-category-analysis (category (string-ascii 50)) (period uint))
  (map-get? category-analysis { category: category, period: period })
)

(define-read-only (get-category-benchmark (category (string-ascii 50)))
  (map-get? category-benchmarks { category: category })
)

(define-read-only (get-supplier-category-spend (supplier (string-ascii 100)) (category (string-ascii 50)))
  (map-get? supplier-category-spend { supplier: supplier, category: category })
)

;; Public functions
(define-public (analyze-category-spend
  (category (string-ascii 50))
  (period uint)
  (total-spend uint)
  (transaction-count uint)
  (top-supplier (string-ascii 100))
)
  (let ((average-transaction (if (> transaction-count u0) (/ total-spend transaction-count) u0)))
    (begin
      (asserts! (> (len category) u0) err-invalid-params)
      (asserts! (> total-spend u0) err-invalid-params)

      (map-set category-analysis
        { category: category, period: period }
        {
          total-spend: total-spend,
          transaction-count: transaction-count,
          average-transaction: average-transaction,
          top-supplier: top-supplier,
          trend-direction: "stable",
          analysis-date: block-height
        }
      )
      (ok true)
    )
  )
)

(define-public (set-category-benchmark
  (category (string-ascii 50))
  (benchmark-spend uint)
  (target-savings uint)
)
  (begin
    (asserts! (> (len category) u0) err-invalid-params)
    (asserts! (> benchmark-spend u0) err-invalid-params)

    (map-set category-benchmarks
      { category: category }
      {
        benchmark-spend: benchmark-spend,
        target-savings: target-savings,
        performance-score: u100
      }
    )
    (ok true)
  )
)

(define-public (update-supplier-category-spend
  (supplier (string-ascii 100))
  (category (string-ascii 50))
  (spend-amount uint)
)
  (begin
    (asserts! (> (len supplier) u0) err-invalid-params)
    (asserts! (> (len category) u0) err-invalid-params)
    (asserts! (> spend-amount u0) err-invalid-params)

    (match (map-get? supplier-category-spend { supplier: supplier, category: category })
      current-data (map-set supplier-category-spend
        { supplier: supplier, category: category }
        {
          total-spend: (+ (get total-spend current-data) spend-amount),
          transaction-count: (+ (get transaction-count current-data) u1)
        }
      )
      (map-set supplier-category-spend
        { supplier: supplier, category: category }
        { total-spend: spend-amount, transaction-count: u1 }
      )
    )
    (ok true)
  )
)

(define-public (calculate-category-variance (category (string-ascii 50)) (actual-spend uint))
  (match (map-get? category-benchmarks { category: category })
    benchmark-data
    (let ((variance (if (>= actual-spend (get benchmark-spend benchmark-data))
                      (- actual-spend (get benchmark-spend benchmark-data))
                      (- (get benchmark-spend benchmark-data) actual-spend))))
      (ok variance)
    )
    (err err-not-found)
  )
)
