# InsureLend

**A DeFi lending smart contract with integrated insurance coverage for lenders and borrowers on the Stacks blockchain**

InsureLend revolutionizes decentralized finance by combining traditional peer-to-peer lending with comprehensive insurance protection, creating a safer and more secure lending environment for all participants.

## 🌟 Features

### Core Lending Features
- **Collateralized Lending**: Secure lending with STX collateral requirements
- **Flexible Loan Terms**: Customizable loan duration and amounts
- **Automated Interest Calculation**: Dynamic interest calculation based on loan duration
- **Instant Loan Processing**: Immediate loan disbursement upon approval
- **Automated Liquidation**: Smart contract-based liquidation for overdue loans

### Insurance Protection
- **Optional Loan Insurance**: Borrowers can purchase insurance coverage for their loans
- **Insurance Pool**: Community-funded insurance pool for enhanced security
- **Automatic Claims Processing**: Smart contract handles insurance payouts automatically
- **Risk Mitigation**: Protection for both lenders and borrowers against defaults

### Pool Management
- **Lending Pool**: Decentralized pool for lender deposits
- **Liquidity Management**: Real-time tracking of available funds
- **Yield Generation**: Interest earnings for lenders
- **Flexible Withdrawals**: Withdraw available funds anytime

## 🔧 Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity 2.0
- **Epoch**: 2.5
- **Collateralization Ratio**: 150% minimum
- **Interest Rate**: 10% annually (simplified for demo)
- **Insurance Premium**: 5% of loan amount
- **Liquidation Threshold**: 150% collateralization required

## 📦 Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development environment
- [Node.js](https://nodejs.org/) v16 or higher
- [Git](https://git-scm.com/)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/InsureLend.git
   cd InsureLend
   ```

2. **Install Dependencies**
   ```bash
   cd InsureLend_contract
   npm install
   ```

3. **Run Tests**
   ```bash
   npm test
   ```

4. **Start Development Environment**
   ```bash
   clarinet console
   ```

## 🚀 Usage Examples

### For Lenders

#### Deposit Funds to Lending Pool
```clarity
;; Deposit 1000 STX to the lending pool
(contract-call? .InsureLend deposit-funds u1000000000)
```

#### Withdraw Available Funds
```clarity
;; Withdraw 500 STX from available balance
(contract-call? .InsureLend withdraw-funds u500000000)
```

#### Check Lender Information
```clarity
;; Get lender deposit information
(contract-call? .InsureLend get-lender-info 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### For Borrowers

#### Request a Loan (Without Insurance)
```clarity
;; Request 500 STX loan with 750 STX collateral for 1000 blocks
(contract-call? .InsureLend request-loan u500000000 u750000000 u1000 false)
```

#### Request an Insured Loan
```clarity
;; Request 500 STX loan with insurance coverage
(contract-call? .InsureLend request-loan u500000000 u750000000 u1000 true)
```

#### Repay a Loan
```clarity
;; Repay loan with ID 1
(contract-call? .InsureLend repay-loan u1)
```

### Insurance Operations

#### Contribute to Insurance Pool
```clarity
;; Contribute 100 STX to the insurance pool
(contract-call? .InsureLend contribute-to-insurance u100000000)
```

#### Check Insurance Policy
```clarity
;; Get insurance policy details for loan ID 1
(contract-call? .InsureLend get-insurance-policy u1)
```

## 📋 Contract Functions Documentation

### Public Functions

#### `deposit-funds(amount: uint)`
Deposits STX tokens into the lending pool.
- **Parameters**: `amount` - Amount of STX to deposit (in microSTX)
- **Returns**: `(response uint uint)` - Success with deposited amount or error code
- **Access**: Anyone

#### `withdraw-funds(amount: uint)`
Withdraws available STX from the lending pool.
- **Parameters**: `amount` - Amount of STX to withdraw (in microSTX)
- **Returns**: `(response uint uint)` - Success with withdrawn amount or error code
- **Access**: Lenders with sufficient available balance

#### `request-loan(amount: uint, collateral: uint, duration-blocks: uint, with-insurance: bool)`
Requests a collateralized loan with optional insurance.
- **Parameters**: 
  - `amount` - Loan amount in microSTX
  - `collateral` - Collateral amount in microSTX (must be ≥150% of loan)
  - `duration-blocks` - Loan duration in blocks
  - `with-insurance` - Whether to purchase insurance coverage
- **Returns**: `(response uint uint)` - Success with loan ID or error code
- **Access**: Anyone with sufficient collateral

#### `repay-loan(loan-id: uint)`
Repays a loan including principal and accrued interest.
- **Parameters**: `loan-id` - Unique identifier of the loan
- **Returns**: `(response uint uint)` - Success with total repayment amount or error code
- **Access**: Original borrower only

#### `liquidate-loan(loan-id: uint)`
Liquidates an overdue loan, using insurance if available.
- **Parameters**: `loan-id` - Unique identifier of the loan
- **Returns**: `(response uint uint)` - Success with loan ID or error code
- **Access**: Anyone (for overdue loans only)

#### `contribute-to-insurance(amount: uint)`
Contributes STX to the community insurance pool.
- **Parameters**: `amount` - Contribution amount in microSTX
- **Returns**: `(response uint uint)` - Success with contributed amount or error code
- **Access**: Anyone

### Read-Only Functions

#### `get-loan(loan-id: uint)`
Retrieves detailed information about a specific loan.

#### `get-lender-info(lender: principal)`
Gets deposit and lending information for a specific lender.

#### `get-insurance-policy(loan-id: uint)`
Retrieves insurance policy details for a loan.

#### `get-pool-balance()`
Returns the current total lending pool balance.

#### `get-insurance-pool-balance()`
Returns the current insurance pool balance.

#### `calculate-interest(principal: uint, rate: uint, blocks: uint)`
Calculates interest for given parameters.

#### `is-loan-overdue(loan-id: uint)`
Checks if a loan is overdue for liquidation.

## 🚀 Deployment Guide

### Local Development Deployment

1. **Start Clarinet Console**
   ```bash
   clarinet console
   ```

2. **Deploy Contract**
   ```clarity
   ::deploy_contracts
   ```

3. **Verify Deployment**
   ```clarity
   ::get_contracts
   ```

### Testnet Deployment

1. **Configure Testnet Settings**
   ```bash
   # Edit settings/Testnet.toml with your testnet configuration
   ```

2. **Deploy to Testnet**
   ```bash
   clarinet deployments apply --network testnet
   ```

### Mainnet Deployment

1. **Update Mainnet Configuration**
   ```bash
   # Edit settings/Mainnet.toml with production settings
   ```

2. **Deploy to Mainnet**
   ```bash
   clarinet deployments apply --network mainnet
   ```

## 🔒 Security Considerations

### Smart Contract Security
- **Collateralization Requirements**: Minimum 150% collateral ratio enforces loan security
- **Access Controls**: Function-level access restrictions prevent unauthorized operations
- **Overflow Protection**: Clarity's built-in arithmetic prevents integer overflow vulnerabilities
- **State Validation**: Comprehensive input validation and state checking

### Operational Security
- **Liquidation Mechanism**: Automated liquidation protects lenders from defaults
- **Insurance Coverage**: Optional insurance provides additional protection layer
- **Emergency Controls**: Contract owner functions for emergency situations

### Risk Factors
- **Smart Contract Risk**: Code is provided as-is; conduct thorough testing before mainnet deployment
- **Market Risk**: STX price volatility may affect collateral values
- **Liquidity Risk**: Pool may not have sufficient funds for large loan requests
- **Oracle Risk**: Current implementation uses simplified interest calculation

### Recommended Practices
- **Thorough Testing**: Test all functions extensively on testnet before mainnet deployment
- **Code Audits**: Consider professional security audits for production deployments
- **Gradual Scaling**: Start with small amounts and gradually increase as confidence grows
- **Monitor Positions**: Regularly monitor loan positions and pool balances

## 🧪 Testing

The project includes comprehensive test suites:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

Test files are located in the `tests/` directory and cover:
- Loan creation and repayment scenarios
- Insurance policy functionality
- Liquidation mechanisms
- Edge cases and error handling

## 🤝 Contributing

We welcome contributions to improve InsureLend! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ISC License - see the LICENSE file for details.

## 📞 Support

For questions, issues, or contributions:
- Open an issue on GitHub
- Join our community discussions
- Review our documentation

## ⚠️ Disclaimer

InsureLend is experimental software. Use at your own risk. The developers are not responsible for any financial losses. Always conduct thorough testing and consider professional audits before deploying to mainnet with significant funds.

---

**Built with ❤️ for the Stacks ecosystem**