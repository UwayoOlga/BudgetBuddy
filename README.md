# BudgetBuddy

A smart expense & budget tracker for students, built with Flutter and Hive.

## Features
- **Expense Logging & Categorization:** Manually enter and categorize expenses (amount, category, date, notes, payment method, recurring).
- **Income Tracking:** Add/view/update/delete income sources (allowance, job, scholarship, etc.).
- **Budget Setting & Alerts:** Set monthly/weekly budgets by category. Visual indicators and in-app notifications if close to exceeding.
- **Savings Goals:** Create, update, and track savings goals with progress bars and celebratory animations.
- **Reports & Graphs:** Visualize spending and income trends, filter by category/payment method, and see summaries.
- **Calendar View:** See all transactions on a monthly calendar.
- **Profile Management:** Update username and password securely.
- **Offline Storage:** All data is stored locally using Hive, with each user’s data isolated and secure.
- **Modern UI:** Clean, responsive, and student-friendly design with a dark purple/white theme.

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)

### Setup
1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd BudgetBuddy
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   flutter pub run build_runner build
   ```
3. **Run the app:**
   ```sh
   flutter run
   ```

### Hive Migration
- All data is now stored using [Hive](https://docs.hivedb.dev/), a fast, secure, and offline-first NoSQL database for Flutter.
- Each user’s data is isolated by their login (username/password).
- No external backend or internet connection required.

## Usage
- **Register/Login:** Create an account or log in. All your data is private and local.
- **Add Expenses/Income:** Use the Add screens to log new transactions. Edit or delete any entry from the list views.
- **Budgets:** Set and manage budgets per category and period. Delete or update as needed.
- **Savings Goals:** Track your savings progress and celebrate achievements.
- **Reports & Calendar:** Visualize your financial activity and trends.
- **Profile:** Update your username and password in the Settings screen.

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](LICENSE)
