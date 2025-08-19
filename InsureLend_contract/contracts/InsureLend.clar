
;; title: InsureLend
;; version: 1.0.0
;; summary: DeFi lending smart contract with integrated insurance coverage
;; description: InsureLend allows users to lend and borrow STX with integrated insurance protection for both lenders and borrowers

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_LOAN_NOT_FOUND (err u102))
(define-constant ERR_LOAN_ALREADY_REPAID (err u103))
(define-constant ERR_LOAN_NOT_DUE (err u104))
(define-constant ERR_INSURANCE_NOT_ACTIVE (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_COLLATERAL_INSUFFICIENT (err u107))

;; Interest rate: 10% annually (simplified to 10 basis points per block for demo)
(define-constant INTEREST_RATE u10)
(define-constant INSURANCE_PREMIUM_RATE u5) ;; 5% of loan amount
(define-constant LIQUIDATION_THRESHOLD u150) ;; 150% collateralization required
(define-constant BLOCKS_PER_YEAR u52560) ;; Approximate blocks per year

;; data vars
(define-data-var next-loan-id uint u1)
(define-data-var total-pool-balance uint u0)
(define-data-var insurance-pool-balance uint u0)

;; data maps
;; Loan structure
(define-map loans
    uint
    {
        borrower: principal,
        lender: principal,
        amount: uint,
        collateral: uint,
        interest-rate: uint,
        start-block: uint,
        due-block: uint,
        repaid: bool,
        insured: bool,
        insurance-premium: uint
    }
)

;; Lender deposits
(define-map lender-deposits
    principal
    {
        total-deposited: uint,
        available-balance: uint,
        loans-outstanding: uint
    }
)

;; Insurance policies
(define-map insurance-policies
    uint ;; loan-id
    {
        premium-paid: uint,
        coverage-amount: uint,
        active: bool
    }
)

;; User insurance contributions
(define-map insurance-contributions
    principal
    uint ;; amount contributed to insurance pool
)

;; public functions

;; Deposit STX to lending pool
(define-public (deposit-funds (amount uint))
    (let (
        (current-deposit (default-to {total-deposited: u0, available-balance: u0, loans-outstanding: u0}
                          (map-get? lender-deposits tx-sender)))
    )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        ;; Transfer STX from sender to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update lender deposits
        (map-set lender-deposits tx-sender
            {
                total-deposited: (+ (get total-deposited current-deposit) amount),
                available-balance: (+ (get available-balance current-deposit) amount),
                loans-outstanding: (get loans-outstanding current-deposit)
            }
        )
        
        ;; Update total pool balance
        (var-set total-pool-balance (+ (var-get total-pool-balance) amount))
        
        (print {action: "deposit", lender: tx-sender, amount: amount})
        (ok amount)
    )
)

;; Withdraw available funds from lending pool
(define-public (withdraw-funds (amount uint))
    (let (
        (current-deposit (unwrap! (map-get? lender-deposits tx-sender) ERR_UNAUTHORIZED))
    )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= amount (get available-balance current-deposit)) ERR_INSUFFICIENT_BALANCE)
        
        ;; Transfer STX from contract to sender
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        
        ;; Update lender deposits
        (map-set lender-deposits tx-sender
            {
                total-deposited: (- (get total-deposited current-deposit) amount),
                available-balance: (- (get available-balance current-deposit) amount),
                loans-outstanding: (get loans-outstanding current-deposit)
            }
        )
        
        ;; Update total pool balance
        (var-set total-pool-balance (- (var-get total-pool-balance) amount))
        
        (print {action: "withdraw", lender: tx-sender, amount: amount})
        (ok amount)
    )
)

;; Request a loan with optional insurance
(define-public (request-loan (amount uint) (collateral uint) (duration-blocks uint) (with-insurance bool))
    (let (
        (loan-id (var-get next-loan-id))
        (due-block (+ block-height duration-blocks))
        (insurance-premium (if with-insurance (/ (* amount INSURANCE_PREMIUM_RATE) u100) u0))
        (total-required (+ collateral insurance-premium))
    )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (> collateral u0) ERR_INVALID_AMOUNT)
        (asserts! (>= collateral (/ (* amount LIQUIDATION_THRESHOLD) u100)) ERR_COLLATERAL_INSUFFICIENT)
        (asserts! (<= amount (var-get total-pool-balance)) ERR_INSUFFICIENT_BALANCE)
        
        ;; Transfer collateral and insurance premium from borrower to contract
        (try! (stx-transfer? total-required tx-sender (as-contract tx-sender)))
        
        ;; Create loan record
        (map-set loans loan-id
            {
                borrower: tx-sender,
                lender: CONTRACT_OWNER, ;; Simplified: contract acts as lender
                amount: amount,
                collateral: collateral,
                interest-rate: INTEREST_RATE,
                start-block: block-height,
                due-block: due-block,
                repaid: false,
                insured: with-insurance,
                insurance-premium: insurance-premium
            }
        )
        
        ;; If insured, create insurance policy and add premium to insurance pool
        (if with-insurance
            (begin
                (map-set insurance-policies loan-id
                    {
                        premium-paid: insurance-premium,
                        coverage-amount: amount,
                        active: true
                    }
                )
                (var-set insurance-pool-balance (+ (var-get insurance-pool-balance) insurance-premium))
            )
            true
        )
        
        ;; Transfer loan amount to borrower
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        
        ;; Update pool balance
        (var-set total-pool-balance (- (var-get total-pool-balance) amount))
        
        ;; Increment loan ID
        (var-set next-loan-id (+ loan-id u1))
        
        (print {action: "loan-requested", borrower: tx-sender, loan-id: loan-id, amount: amount, insured: with-insurance})
        (ok loan-id)
    )
)

;; Repay a loan
(define-public (repay-loan (loan-id uint))
    (let (
        (loan (unwrap! (map-get? loans loan-id) ERR_LOAN_NOT_FOUND))
        (interest (calculate-interest (get amount loan) (get interest-rate loan) 
                                    (- block-height (get start-block loan))))
        (total-repayment (+ (get amount loan) interest))
    )
        (asserts! (is-eq tx-sender (get borrower loan)) ERR_UNAUTHORIZED)
        (asserts! (not (get repaid loan)) ERR_LOAN_ALREADY_REPAID)
        
        ;; Transfer repayment from borrower to contract
        (try! (stx-transfer? total-repayment tx-sender (as-contract tx-sender)))
        
        ;; Return collateral to borrower
        (try! (as-contract (stx-transfer? (get collateral loan) tx-sender tx-sender)))
        
        ;; Mark loan as repaid
        (map-set loans loan-id
            (merge loan {repaid: true})
        )
        
        ;; Add repayment to pool balance
        (var-set total-pool-balance (+ (var-get total-pool-balance) total-repayment))
        
        (print {action: "loan-repaid", borrower: tx-sender, loan-id: loan-id, amount: total-repayment})
        (ok total-repayment)
    )
)

;; Liquidate an overdue loan
(define-public (liquidate-loan (loan-id uint))
    (let (
        (loan (unwrap! (map-get? loans loan-id) ERR_LOAN_NOT_FOUND))
        (insurance-policy (map-get? insurance-policies loan-id))
    )
        (asserts! (not (get repaid loan)) ERR_LOAN_ALREADY_REPAID)
        (asserts! (>= block-height (get due-block loan)) ERR_LOAN_NOT_DUE)
        
        ;; If loan is insured and insurance is active, pay from insurance pool
        (if (and (get insured loan) 
                 (is-some insurance-policy)
                 (get active (unwrap-panic insurance-policy)))
            (begin
                ;; Pay lender from insurance pool
                (let ((coverage (get coverage-amount (unwrap-panic insurance-policy))))
                    (var-set insurance-pool-balance (- (var-get insurance-pool-balance) coverage))
                    (var-set total-pool-balance (+ (var-get total-pool-balance) coverage))
                )
                ;; Deactivate insurance policy
                (map-set insurance-policies loan-id
                    (merge (unwrap-panic insurance-policy) {active: false})
                )
            )
            ;; If not insured, liquidate collateral
            (var-set total-pool-balance (+ (var-get total-pool-balance) (get collateral loan)))
        )
        
        ;; Mark loan as repaid (liquidated)
        (map-set loans loan-id
            (merge loan {repaid: true})
        )
        
        (print {action: "loan-liquidated", loan-id: loan-id, insured: (get insured loan)})
        (ok loan-id)
    )
)

;; Contribute to insurance pool
(define-public (contribute-to-insurance (amount uint))
    (let (
        (current-contribution (default-to u0 (map-get? insurance-contributions tx-sender)))
    )
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        ;; Transfer STX from sender to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update insurance contributions
        (map-set insurance-contributions tx-sender (+ current-contribution amount))
        
        ;; Update insurance pool balance
        (var-set insurance-pool-balance (+ (var-get insurance-pool-balance) amount))
        
        (print {action: "insurance-contribution", contributor: tx-sender, amount: amount})
        (ok amount)
    )
)

;; read only functions

;; Get loan details
(define-read-only (get-loan (loan-id uint))
    (map-get? loans loan-id)
)

;; Get lender deposit info
(define-read-only (get-lender-info (lender principal))
    (map-get? lender-deposits lender)
)

;; Get insurance policy info
(define-read-only (get-insurance-policy (loan-id uint))
    (map-get? insurance-policies loan-id)
)

;; Get total pool balance
(define-read-only (get-pool-balance)
    (var-get total-pool-balance)
)

;; Get insurance pool balance
(define-read-only (get-insurance-pool-balance)
    (var-get insurance-pool-balance)
)

;; Calculate interest for a loan
(define-read-only (calculate-interest (principal uint) (rate uint) (blocks uint))
    (/ (* (* principal rate) blocks) (* u100 BLOCKS_PER_YEAR))
)

;; Get next loan ID
(define-read-only (get-next-loan-id)
    (var-get next-loan-id)
)

;; Check if loan is overdue
(define-read-only (is-loan-overdue (loan-id uint))
    (match (map-get? loans loan-id)
        loan (and (not (get repaid loan)) (>= block-height (get due-block loan)))
        false
    )
)

;; Get user's insurance contribution
(define-read-only (get-insurance-contribution (user principal))
    (default-to u0 (map-get? insurance-contributions user))
)

;; private functions

;; Initialize contract (could be called once by deployer)
(define-private (initialize-contract)
    (begin
        (var-set total-pool-balance u0)
        (var-set insurance-pool-balance u0)
        (var-set next-loan-id u1)
        (ok true)
    )
)
