(define-constant CONTRACT_OWNER tx-sender)

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_VOTING_PERIOD_ENDED (err u102))
(define-constant ERR_ALREADY_VOTED (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_PROPOSAL_ALREADY_EXECUTED (err u106))
(define-constant ERR_VOTING_PERIOD_NOT_ENDED (err u107))
(define-constant ERR_PROPOSAL_NOT_APPROVED (err u108))
(define-constant ERR_VOTER_NOT_REGISTERED (err u109))
(define-constant ERR_VOTER_ALREADY_REGISTERED (err u110))
(define-constant ERR_ALREADY_CANCELLED (err u111))
(define-constant ERR_CANNOT_CANCEL_EXECUTED (err u112))
(define-constant ERR_INVALID_CANCELLATION (err u113))

(define-data-var proposal-counter uint u0)
(define-data-var total-budget uint u1000000000)
(define-data-var admin principal CONTRACT_OWNER)

(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    budget-requested: uint,
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    created-at: uint,
    voting-end: uint,
    executed: bool,
    approved: bool
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, weight: uint }
)

(define-map registered-voters
  { voter: principal }
  { registration-block: uint, voting-power: uint }
)

(define-map voter-proposals
  { voter: principal, proposal-id: uint }
  { voted: bool }
)

(define-map budget-allocations
  { proposal-id: uint }
  { allocated-amount: uint, disbursed: bool }
)

(define-map proposal-cancellations
  { proposal-id: uint }
  { cancelled: bool, cancelled-by: principal, cancellation-reason: (string-ascii 256), cancelled-at-block: uint }
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-voter-registration (voter principal))
  (map-get? registered-voters { voter: voter })
)

(define-read-only (get-total-budget)
  (var-get total-budget)
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

(define-read-only (get-admin)
  (var-get admin)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (default-to false
    (get voted (map-get? voter-proposals { voter: voter, proposal-id: proposal-id }))
  )
)

(define-read-only (is-voter-registered (voter principal))
  (is-some (map-get? registered-voters { voter: voter }))
)

(define-read-only (get-current-block)
  stacks-block-height
)

(define-read-only (calculate-voting-power (voter principal))
  (let ((registration (map-get? registered-voters { voter: voter })))
    (match registration
      voter-data (get voting-power voter-data)
      u1
    )
  )
)

(define-read-only (get-proposal-status (proposal-id uint))
  (let ((proposal (map-get? proposals { proposal-id: proposal-id })))
    (match proposal
      prop-data
      {
        total-votes: (+ (get votes-for prop-data) (get votes-against prop-data)),
        approval-rate: (if (> (+ (get votes-for prop-data) (get votes-against prop-data)) u0)
                         (/ (* (get votes-for prop-data) u100) (+ (get votes-for prop-data) (get votes-against prop-data)))
                         u0),
        voting-active: (<= stacks-block-height (get voting-end prop-data)),
        budget-sufficient: (<= (get budget-requested prop-data) (var-get total-budget))
      }
      { total-votes: u0, approval-rate: u0, voting-active: false, budget-sufficient: false }
    )
  )
)

(define-read-only (get-cancellation-status (proposal-id uint))
  (map-get? proposal-cancellations { proposal-id: proposal-id })
)

(define-read-only (is-proposal-cancelled (proposal-id uint))
  (let ((cancellation (map-get? proposal-cancellations { proposal-id: proposal-id })))
    (match cancellation
      cancel-data (get cancelled cancel-data)
      false
    )
  )
)

(define-public (register-voter)
  (let ((caller tx-sender))
    (asserts! (not (is-voter-registered caller)) ERR_VOTER_ALREADY_REGISTERED)
    (ok (map-set registered-voters
      { voter: caller }
      {
        registration-block: stacks-block-height,
        voting-power: u1
      }
    ))
  )
)

(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (budget-requested uint) (voting-duration uint))
  (let
    (
      (caller tx-sender)
      (proposal-id (+ (var-get proposal-counter) u1))
      (current-block stacks-block-height)
      (voting-end (+ current-block voting-duration))
    )
    (asserts! (is-voter-registered caller) ERR_VOTER_NOT_REGISTERED)
    (asserts! (> budget-requested u0) ERR_INVALID_AMOUNT)
    (asserts! (<= budget-requested (var-get total-budget)) ERR_INSUFFICIENT_BALANCE)
    (map-set proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        budget-requested: budget-requested,
        proposer: caller,
        votes-for: u0,
        votes-against: u0,
        created-at: current-block,
        voting-end: voting-end,
        executed: false,
        approved: false
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (cast-vote (proposal-id uint) (vote-for bool))
  (let
    (
      (caller tx-sender)
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
      (voter-power (calculate-voting-power caller))
      (current-votes-for (get votes-for proposal))
      (current-votes-against (get votes-against proposal))
    )
    (asserts! (is-voter-registered caller) ERR_VOTER_NOT_REGISTERED)
    (asserts! (not (is-proposal-cancelled proposal-id)) ERR_ALREADY_CANCELLED)
    (asserts! (<= stacks-block-height (get voting-end proposal)) ERR_VOTING_PERIOD_ENDED)
    (asserts! (not (has-voted proposal-id caller)) ERR_ALREADY_VOTED)
    
    (map-set votes
      { proposal-id: proposal-id, voter: caller }
      { vote: vote-for, weight: voter-power }
    )
    
    (map-set voter-proposals
      { voter: caller, proposal-id: proposal-id }
      { voted: true }
    )
    
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote-for (+ current-votes-for voter-power) current-votes-for),
        votes-against: (if vote-for current-votes-against (+ current-votes-against voter-power))
      })
    )
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-proposal-cancelled proposal-id)) ERR_ALREADY_CANCELLED)
    (asserts! (> stacks-block-height (get voting-end proposal)) ERR_VOTING_PERIOD_NOT_ENDED)
    (asserts! (not (get executed proposal)) ERR_PROPOSAL_ALREADY_EXECUTED)
    
    (let
      (
        (votes-for (get votes-for proposal))
        (votes-against (get votes-against proposal))
        (total-votes (+ votes-for votes-against))
        (approval-threshold (/ total-votes u2))
        (approved (> votes-for approval-threshold))
      )
      
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal {
          executed: true,
          approved: approved
        })
      )
      
      (if approved
        (begin
          (var-set total-budget (- (var-get total-budget) (get budget-requested proposal)))
          (map-set budget-allocations
            { proposal-id: proposal-id }
            { allocated-amount: (get budget-requested proposal), disbursed: false }
          )
        )
        true
      )
      
      (ok approved)
    )
  )
)

(define-public (disburse-funds (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
      (allocation (unwrap! (map-get? budget-allocations { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_APPROVED))
    )
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (get approved proposal) ERR_PROPOSAL_NOT_APPROVED)
    (asserts! (not (get disbursed allocation)) ERR_PROPOSAL_ALREADY_EXECUTED)
    
    (map-set budget-allocations
      { proposal-id: proposal-id }
      (merge allocation { disbursed: true })
    )
    (ok (get allocated-amount allocation))
  )
)

(define-public (update-voter-power (voter principal) (new-power uint))
  (let ((registration (unwrap! (map-get? registered-voters { voter: voter }) ERR_VOTER_NOT_REGISTERED)))
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (map-set registered-voters
      { voter: voter }
      (merge registration { voting-power: new-power })
    )
    (ok new-power)
  )
)

(define-public (add-budget (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (var-set total-budget (+ (var-get total-budget) amount))
    (ok (var-get total-budget))
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (var-set admin new-admin)
    (ok new-admin)
  )
)

(define-public (withdraw-proposal (proposal-id uint) (reason (string-ascii 256)))
  (let
    (
      (caller tx-sender)
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
      (is-cancelled (is-proposal-cancelled proposal-id))
    )
    (asserts! (is-eq caller (get proposer proposal)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get executed proposal)) ERR_CANNOT_CANCEL_EXECUTED)
    (asserts! (not is-cancelled) ERR_ALREADY_CANCELLED)
    (map-set proposal-cancellations
      { proposal-id: proposal-id }
      { cancelled: true, cancelled-by: caller, cancellation-reason: reason, cancelled-at-block: stacks-block-height }
    )
    (var-set total-budget (+ (var-get total-budget) (get budget-requested proposal)))
    (ok true)
  )
)

(define-public (veto-proposal (proposal-id uint) (reason (string-ascii 256)))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
      (is-cancelled (is-proposal-cancelled proposal-id))
    )
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (not is-cancelled) ERR_ALREADY_CANCELLED)
    (map-set proposal-cancellations
      { proposal-id: proposal-id }
      { cancelled: true, cancelled-by: tx-sender, cancellation-reason: reason, cancelled-at-block: stacks-block-height }
    )
    (var-set total-budget (+ (var-get total-budget) (get budget-requested proposal)))
    (ok true)
  )
)

(define-public (emergency-pause-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { voting-end: stacks-block-height })
    )
    (ok true)
  )
)
