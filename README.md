# 🗳️ PublicVote - Community Voting on Public Works

> 🏛️ A decentralized protocol for citizens to vote on local public works projects and budgets on the Stacks blockchain.

## 📋 Overview

PublicVote enables transparent, democratic decision-making for public infrastructure projects through blockchain-based voting. Citizens can register as voters, propose public works projects, and collectively decide on budget allocations through secure, immutable voting processes.

## 🚀 Features

- 👥 **Voter Registration**: Citizens can register to participate in democratic processes
- 📝 **Proposal Creation**: Submit public works project proposals with budget requirements
- 🗳️ **Weighted Voting**: Cast votes with configurable voting power
- 💰 **Budget Management**: Automated budget allocation for approved proposals
- 🔒 **Admin Controls**: Administrative functions for system governance
- ⏰ **Time-based Voting**: Configurable voting periods with automatic closure
- 📊 **Real-time Status**: Live proposal status and voting analytics

## 🛠️ Development Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Node.js (for testing)
- Git

### Installation

```bash
git clone https://github.com/your-username/Community-Voting-on-Public-Works.git
cd Community-Voting-on-Public-Works
npm install
```

### 🔧 Fix Line Endings (Windows)
```powershell
(Get-Content "contracts/PublicVote.clar" -Raw).Replace("`r`n", "`n") | Set-Content "contracts/PublicVote.clar" -NoNewline
```

### ✅ Compile Contract
```bash
clarinet check
```

### 🧪 Run Tests
```bash
npm test
```

## 📖 Smart Contract API

### 📊 Read-Only Functions

#### `get-proposal(proposal-id: uint)`
Retrieve proposal details by ID.

#### `get-total-budget()`
Get current available budget for public works.

#### `is-voter-registered(voter: principal)`
Check if an address is registered to vote.

#### `get-proposal-status(proposal-id: uint)`
Get comprehensive proposal status including vote counts and approval rate.

### 🔧 Public Functions

#### `register-voter()`
Register caller as eligible voter.

```clarity
(contract-call? .PublicVote register-voter)
```

#### `create-proposal(title, description, budget-requested, voting-duration)`
Submit new public works proposal.

```clarity
(contract-call? .PublicVote create-proposal 
  "New Park Development" 
  "Build a community park with playground equipment" 
  u50000000 
  u1000)
```

#### `cast-vote(proposal-id, vote-for)`
Vote on a proposal (true = support, false = oppose).

```clarity
(contract-call? .PublicVote cast-vote u1 true)
```

#### `execute-proposal(proposal-id)`
**(Admin only)** Execute voting results and allocate budget if approved.

```clarity
(contract-call? .PublicVote execute-proposal u1)
```

#### `disburse-funds(proposal-id)`
**(Admin only)** Release allocated funds for approved project.

```clarity
(contract-call? .PublicVote disburse-funds u1)
```

## 🎯 Usage Examples

### 1. 👤 Citizen Registration
```clarity
;; Register as voter
(contract-call? .PublicVote register-voter)
```

### 2. 📝 Creating a Proposal
```clarity
;; Submit park improvement proposal
(contract-call? .PublicVote create-proposal 
  "Downtown Park Renovation" 
  "Install new benches, lighting, and walking paths in downtown park area" 
  u75000000 
  u2016) ;; ~2 weeks voting period
```

### 3. 🗳️ Voting Process
```clarity
;; Vote in favor of proposal #1
(contract-call? .PublicVote cast-vote u1 true)

;; Vote against proposal #2
(contract-call? .PublicVote cast-vote u2 false)
```

### 4. 📊 Checking Results
```clarity
;; Get proposal status
(contract-call? .PublicVote get-proposal-status u1)

;; Check if voting period ended
(contract-call? .PublicVote get-proposal u1)
```

## 🏛️ Governance Model

### Voting Process
1. **Registration**: Citizens register once to gain voting rights
2. **Proposal**: Registered voters submit project proposals with budget requests
3. **Voting**: Open voting period with configurable duration
4. **Execution**: Admin executes results after voting period ends
5. **Disbursement**: Funds released for approved projects

### Budget Allocation
- Initial budget: 1,000,000,000 microSTX
- Approved proposals deduct from available budget
- Admin can add additional budget as needed
- Failed proposals don't consume budget

### Security Features
- ✅ Prevents double voting
- ✅ Time-bound voting periods
- ✅ Admin-only execution functions
- ✅ Immutable voting records
- ✅ Budget overflow protection

## 🔐 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `ERR_NOT_AUTHORIZED` | Caller lacks required permissions |
| `u101` | `ERR_PROPOSAL_NOT_FOUND` | Proposal ID doesn't exist |
| `u102` | `ERR_VOTING_PERIOD_ENDED` | Cannot vote after deadline |
| `u103` | `ERR_ALREADY_VOTED` | Voter already cast ballot |
| `u104` | `ERR_INVALID_AMOUNT` | Invalid budget amount |
| `u105` | `ERR_INSUFFICIENT_BALANCE` | Not enough budget available |
| `u106` | `ERR_PROPOSAL_ALREADY_EXECUTED` | Proposal already processed |
| `u107` | `ERR_VOTING_PERIOD_NOT_ENDED` | Voting still active |
| `u108` | `ERR_PROPOSAL_NOT_APPROVED` | Proposal rejected by voters |
| `u109` | `ERR_VOTER_NOT_REGISTERED` | Must register before participation |
| `u110` | `ERR_VOTER_ALREADY_REGISTERED` | Already registered |

## 📈 Contract Statistics

- **Lines of Code**: 291 lines
- **Functions**: 14 public + 10 read-only
- **Data Maps**: 5 storage maps
- **Error Codes**: 11 comprehensive error types

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and ensure `clarinet check` passes
4. Commit changes (`git commit -m 'feat: add amazing feature'`)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Clarinet](https://docs.hiro.so/stacks/clarinet)
- Powered by [Stacks Blockchain](https://www.stacks.co/)
- Inspired by democratic governance principles

---

💡 **Ready to participate in decentralized democracy?** Start by registering as a voter and proposing your first public works project!
