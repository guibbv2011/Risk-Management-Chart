# Risk Management Trading App

A comprehensive Flutter application designed for traders who need to monitor their trading performance and manage risk effectively. This app implements professional risk management principles with real-time calculations and dynamic balance tracking.

## 🎯 Purpose

This project was created for traders who need to monitor their account balance with precise risk calculations. The application helps traders maintain discipline by enforcing risk limits and providing clear visualization of their trading performance.

## ✨ Features

### 📊 Real-Time Trading Dashboard
- **Interactive P&L Chart**: Visual representation of cumulative profit/loss over time
- **Dynamic Balance Tracking**: Real-time account balance updates after each trade
- **Trailing Drawdown Feature**: Your drawdown limits are dynamically adjusted based on trading performance.
- **Risk Status Indicator**: Color-coded risk levels (Low, Medium, High, Critical)

### 🛡️ Advanced Risk Management
- **Max Drawdown Control**: Set absolute dollar amount for maximum account drawdown
- **Loss Per Trade Percentage**: Configure risk percentage per individual trade
- **Dynamic Max Loss Calculation**: Automatically calculates max loss per trade based on remaining risk capacity
- **Unlimited Profit Potential**: No limits on positive trades - only losses are restricted
- **Smart Risk Validation**: Prevents trades that would exceed risk parameters

### 🔄 Dynamic Drawdown Management
- **Static Mode**: Traditional fixed max drawdown amount
- **Dynamic Mode**: Max drawdown increases when profits exceed initial balance
- **Toggle Control**: Easy switching between static and dynamic modes via dialog

### 📱 User Interface
- **Modern Material Design**: Dark theme with intuitive controls
- **Responsive Layout**: Adapts to different screen sizes
- **Interactive Dialogs**: User-friendly input forms with validation
- **Real-time Updates**: Instant UI updates using reactive programming
- **Error Handling**: Comprehensive error messages and validation

### 🏗️ Architecture
- **MVVM Pattern**: Clean separation of concerns
- **Reactive State Management**: Uses Signals for efficient state updates
- **Repository Pattern**: Abstracted data layer for easy testing and maintenance
- **Service Layer**: Business logic encapsulation
- **Component-based UI**: Reusable widgets and components
- **Cross-Platform Storage**: IndexedDB on web, SQLite on native platforms

## 🔧 How It Works

### Initial Setup
1. **Set Max Drawdown**: Enter the maximum dollar amount you're willing to lose (e.g., $1,000)
2. **Configure Loss Percentage**: Set the percentage of remaining risk per trade (e.g., 5%)
3. **Toggle Dynamic Mode**: Choose whether max drawdown should increase with profits

### Trading Process
1. **Risk Calculation**: System calculates max loss per trade: `Remaining Risk × Loss % = Max Loss`
2. **Trade Entry**: Add trades (positive for profits, negative for losses)
3. **Real-time Validation**: System prevents trades exceeding risk limits
4. **Balance Updates**: Account balance and risk capacity update automatically
5. **Visual Feedback**: Chart and indicators update in real-time

### Example Scenario
```
Initial Settings:
- Account Balance: $10,000
- Max Drawdown: $1,000
- Loss Per Trade: 5%
- Max Loss Per Trade: $1,000 × 5% = $50

After -$200 in losses:
- Current Balance: $9,800
- Remaining Risk: $800
- New Max Loss Per Trade: $800 × 5% = $40

With Dynamic Mode ON and +$500 profit:
- Current Balance: $10,500
- Max Drawdown increases to: $1,500
- Remaining Risk: $1,500
- Max Loss Per Trade: $1,500 × 5% = $75
```

## 📈 Key Benefits

- **Disciplined Trading**: Enforces risk management rules automatically
- **Visual Performance Tracking**: Clear charts showing trading progress
- **Flexible Risk Management**: Adaptive to different trading styles
- **Professional Grade**: Implements industry-standard risk management practices
- **User-Friendly**: Simple interface for complex calculations
- **Scalable Architecture**: Easy to extend with new features

## 🛠️ Technical Implementation

- **Framework**: Flutter for cross-platform compatibility
- **State Management**: Signals for reactive programming
- **Charts**: Syncfusion Flutter Charts for professional visualization
- **Architecture**: MVVM with Repository and Service patterns
- **Data Persistence**: Cross-platform storage with IndexedDB (web) and SQLite (native)
- **Storage Packages**: `idb_sqflite` and `idb_shim` for unified storage API
- **Validation**: Comprehensive input validation and error handling

## 💾 Storage Implementation

The app now features a unified storage system that works seamlessly across all platforms:

### Cross-Platform Storage
- **Web**: Uses IndexedDB for persistent browser storage
- **Mobile/Desktop**: Uses SQLite for native database storage
- **Unified API**: Same interface across all platforms using `idb_sqflite`

### Storage Features
- **Automatic Migration**: Seamless switching between storage implementations
- **Performance Optimized**: Indexed queries for fast data retrieval
- **Transactional**: ACID-compliant operations
- **Development Tools**: Built-in storage demo and testing utilities

### Automatic Data Persistence
The app automatically:
- Saves all trades and settings when modified
- Loads existing data on app startup
- Maintains data across browser sessions (web)
- Stores data locally on device (mobile/desktop)

For detailed implementation guide, see [INDEXEDDB_STORAGE.md](INDEXEDDB_STORAGE.md)

TODO:

Free Version:
- [x] - Add data dynamically, from the floating action button, which opens a text entry.
- [x] - Zoom in/out on the X and Y axes.
- [x] - Store data on the local disk automatically.
      - Native storage implementation
      - Mobile storage implementation
      - Web storage implementation
      - All user data automatically saved and loaded

Paid Version:
- [ ] - Add ads.
- [ ] - Add payment to remove ads
OR:
- [ ] - Monthly/Annual Subscription