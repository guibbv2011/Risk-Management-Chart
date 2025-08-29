# Quick Start Guide

## Welcome to Risk Management Trading App! 🚀

This guide will help you get started with the Risk Management Trading App in just a few minutes. Follow these steps to set up your first risk parameters and start tracking your trades.

## Table of Contents
1. [First Launch](#first-launch)
2. [Setting Up Risk Parameters](#setting-up-risk-parameters)
3. [Adding Your First Trade](#adding-your-first-trade)
4. [Understanding the Interface](#understanding-the-interface)
5. [Common Workflows](#common-workflows)
6. [Tips for Success](#tips-for-success)

## First Launch

When you first open the app, you'll see:

```
┌─────────────────────────────────────────┐
│          Risk Management App            │
├─────────────────────────────────────────┤
│  📊 Empty Chart (no trades yet)         │
│                                         │
│  🚦 Risk Status: Low Risk               │
│                                         │
│  🎛️ Controls:                          │
│     [Max DD ($)]  [% Loss]  [200.00]   │
│                            [+ Add]      │
└─────────────────────────────────────────┘
```

**Default Settings:**
- Account Balance: $10,000
- Max Drawdown: $1,000
- Loss Per Trade: 2%
- Max Loss Per Trade: $20 (calculated)

## Setting Up Risk Parameters

### Step 1: Set Your Maximum Drawdown

The maximum total amount you're willing to lose from your account.

1. **Tap the "Max DD ($)" button**
2. **Enter your maximum drawdown in dollars** (e.g., 500 for $500)
3. **Choose Dynamic Mode (Optional):**
   - ✅ ON: Max drawdown increases with profits
   - ❌ OFF: Fixed max drawdown amount
4. **Tap "Set Max Drawdown"**

**Example:**
```
Input: 500
Result: Max Drawdown = $500
```

### Step 2: Set Your Loss Per Trade Percentage

The percentage of your remaining risk you want to risk per trade.

1. **Tap the "% Loss" button**
2. **Enter percentage** (e.g., 5 for 5%)
3. **Tap "Set Loss Per Trade"**

**Example:**
```
Input: 5
Result: 5% risk per trade
Max Loss Per Trade: $500 × 5% = $25
```

### Visual Feedback
After setting parameters, you'll see the "Max Loss ($)" value update automatically in the control panel.

## Adding Your First Trade

### Step 1: Open Trade Dialog

**Tap the "Add Trade" button** (the + icon on the right)

### Step 2: Enter Trade Result

**Enter your trade result:**
- **Profit:** Enter positive number (e.g., 75.50)
- **Loss:** Enter negative number (e.g., -25.00)

### Step 3: Confirm

**Tap "Add Trade"** to save

### What Happens Next

1. **Chart Updates:** New point appears on the P&L curve
2. **Balance Updates:** Your account balance adjusts
3. **Risk Recalculates:** Max loss per trade may change
4. **Status Updates:** Risk status indicator may change color

## Understanding the Interface

### 📊 Chart Area
- **X-axis:** Trade number (1, 2, 3, ...)
- **Y-axis:** Cumulative profit/loss ($)
- **Line:** Your trading performance over time
- **Interactions:** Pinch to zoom, drag to pan

### 🚦 Risk Status Indicator
Color-coded risk levels based on remaining capacity:

| Color | Status | Meaning |
|-------|--------|---------|
| 🟢 Green | Low Risk | > 50% risk capacity remaining |
| 🟠 Orange | Medium Risk | 20-50% risk capacity remaining |
| 🔴 Red | High Risk | 0-20% risk capacity remaining |
| ⚫ Black | Critical | No risk capacity remaining |

### 🎛️ Control Panel
- **Max DD ($):** Configure maximum drawdown
- **% Loss:** Set loss percentage per trade
- **Max Loss ($):** Shows calculated max loss (updates automatically)
- **Add Trade:** Add new trade results

### ℹ️ Information Dialog
**Tap the info icon** (ℹ️) in the top-right to see detailed statistics:
- Total trades count
- Total P&L
- Win rate percentage
- Current vs. max drawdown
- Average win/loss amounts
- Risk/reward ratio

## Common Workflows

### Workflow 1: Daily Trading Session

```
1. Check current risk status → 🟢 Low Risk
2. Note max loss per trade → $25
3. Plan trades within limit
4. Add trade results as they complete:
   - Trade 1: +45.00 ✅
   - Trade 2: -15.00 ✅  
   - Trade 3: -30.00 ❌ (exceeds $25 limit)
5. Review updated chart and statistics
```

### Workflow 2: Weekly Risk Review

```
1. Open info dialog → Review statistics
2. Check win rate → Aim for > required rate
3. Analyze risk/reward ratio → Aim for > 1.5
4. Adjust loss percentage if needed
5. Consider enabling dynamic mode if profitable
```

### Workflow 3: Risk Limit Hit

```
1. Risk status turns 🔴 Critical
2. App prevents further loss trades
3. Options:
   - Wait for winning trades to recover
   - Clear trades and start fresh
   - Increase max drawdown (not recommended)
```

## Tips for Success

### 🎯 Risk Management Best Practices

1. **Start Conservative**
   - Begin with 1-2% loss per trade
   - Use fixed drawdown mode initially
   - Gradually increase as you gain confidence

2. **Respect the Limits**
   - Never override risk warnings
   - If trade exceeds limit, reduce position size
   - Trust the mathematical safeguards

3. **Monitor Regularly**
   - Check risk status before each trade
   - Review statistics weekly
   - Adjust parameters based on performance

### 📈 Using Dynamic Mode Effectively

**When to Enable:**
- Consistently profitable over 20+ trades
- Win rate above required minimum
- Good risk/reward ratio (> 1.5)

**Benefits:**
- Risk capacity grows with profits
- Larger position sizes when winning
- Maintains original risk if account drops

**Example:**
```
Static Mode:
- Start: $10,000, Max DD: $1,000
- After +$500 profit: Still $1,000 max DD
- Risk capacity: $1,000

Dynamic Mode:
- Start: $10,000, Max DD: $1,000  
- After +$500 profit: $1,500 max DD
- Risk capacity: $1,500 (50% increase!)
```

### 🔍 Reading the Statistics

**Win Rate Interpretation:**
- 60%+ → Excellent
- 50-60% → Good  
- 40-50% → Acceptable (with good R:R)
- <40% → Needs improvement

**Risk/Reward Ratio:**
- 3:1+ → Excellent
- 2:1+ → Good
- 1.5:1+ → Acceptable
- <1.5:1 → Needs higher win rate

### ⚠️ Common Mistakes to Avoid

1. **Ignoring Risk Limits**
   - Don't manually override safety checks
   - Respect the max loss per trade

2. **Setting Unrealistic Parameters**
   - Avoid > 10% loss per trade for beginners
   - Don't set max drawdown > 20% of account

3. **Emotional Trading**
   - Stick to the plan when losing
   - Don't increase risk to "win back" losses

4. **Not Recording All Trades**
   - Record every trade, win or loss
   - Include all fees and slippage

## Quick Reference

### Essential Formulas
```
Max Loss Per Trade = Remaining Risk × Loss % / 100
Remaining Risk = Max Drawdown - Current Drawdown
Current Drawdown = Account Balance - Current Balance
Win Rate = Winning Trades / Total Trades × 100
```

### Keyboard Shortcuts
- **Add Trade:** Tap + button or use Add Trade action
- **Info:** Tap ℹ️ for detailed statistics
- **Clear All:** Hold and tap clear button (confirmation required)

### Default Settings
```
Account Balance: $10,000
Max Drawdown: $1,000 (10% of account)
Loss Per Trade: 2%
Dynamic Mode: OFF
```

## What's Next?

Once you're comfortable with the basics:

1. **Explore Advanced Features**
   - Try dynamic drawdown mode
   - Experiment with different risk percentages
   - Use the position size calculator (coming soon)

2. **Review Documentation**
   - Check the main project README.md for detailed features
   - Review the storage documentation for persistence details
   - Understand the risk management calculations in the API docs

3. **Optimize Your Strategy**
   - Track performance over time
   - Adjust parameters based on results
   - Develop consistent trading habits

## Need Help?

- **Troubleshooting:** See the main TROUBLESHOOTING.md file
- **Storage Issues:** Check the storage documentation folder
- **API Reference:** Review the models.md and risk-calculations.md files

---

**Remember:** The goal is not to eliminate risk, but to manage it intelligently. This app helps you stay disciplined and trade within your means. Start small, be consistent, and let the mathematics work in your favor! 

Happy trading! 📈