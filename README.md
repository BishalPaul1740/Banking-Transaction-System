# Banking-Transaction-System
A secure and scalable banking transaction system built using MySQL, implementing ACID principles for data integrity. It supports account creation, deposits, withdrawals, and inter-account transfers with real-time balance updates and transaction history.

---

## 📁 Table of Contents

- [Features](#features)
- [Database Schema](#database-schema)
- [Technologies Used](#technologies-used)
- [Setup Instructions](#setup-instructions)
- [Core Procedures](#core-procedures)
- [Functions](#functions)
- [Contributors](#contributors)

---

## ✅ Features

- Create and manage customer accounts
- Perform deposits, withdrawals, and transfers
- Maintain transaction history
- Automatically log every transaction in an audit table
- Account balance updates with validation
- Get account status with a user-defined function

---

## 🗄️ Database Schema

- **Customer**: Stores customer details
- **Branch**: Branch info (if applicable)
- **Account**: Manages balance, status, account type
- **Transaction**: Logs every transaction with timestamps
- **AuditLog**: Stores audit trail for every transaction

---

## 🛠️ Technologies Used

- SQL (DDL, DML)
- SQL (Procedures & Functions)
- Any SQL GUI (like MySQL Workbench)

---

## ⚙️ Setup Instructions

1. **Clone this repository**
2. **Create the database:**
   ```sql
   CREATE DATABASE BankSystem;
   USE BankSystem;
**Run the SQL files:**

Create all tables

Insert initial data

Define procedures and triggers

Create utility functions

## Core Procedures
1. deposit_money(p_account_id, p_amount)
Deposits a specified amount into an account.

2. withdraw_money(p_account_id, p_amount)
Withdraws funds from an account if sufficient balance exists.

3. transfer_money(p_sender_account_id, p_receiver_account_id, p_amount)
Transfers funds between two accounts with checks.

## Functions
get_account_status(account_id)
Returns account status ('active', 'inactive', etc.) for a given account.


## Contributors
Bishal Paul
