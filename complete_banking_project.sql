-- ================================
-- Banking System Database Schema
-- ================================

-- DROP and CREATE database for a clean setup
DROP DATABASE IF EXISTS BankingSystem;
CREATE DATABASE BankingSystem;
USE BankingSystem;

-- =====================
-- 1. CUSTOMER TABLE
-- =====================
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================
-- 2. BRANCH TABLE
-- =====================
CREATE TABLE Branch (
    branch_id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    address TEXT,
    IFSC_code VARCHAR(20) UNIQUE NOT NULL
);

-- =====================
-- 3. ACCOUNT TABLE
-- =====================
CREATE TABLE Account (
    account_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    customer_id INT NOT NULL,
    account_type ENUM('savings', 'current', 'fixed deposit') DEFAULT 'savings',
    balance DECIMAL(12,2) DEFAULT 0.00,
    status ENUM('active', 'frozen', 'closed') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    branch_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (branch_id) REFERENCES Branch(branch_id)
);

-- ==========================
-- 4. TRANSACTION TABLE
-- ==========================
CREATE TABLE Transaction (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    sender_account_id INT,
    receiver_account_id INT,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    transaction_type ENUM('deposit', 'withdrawal', 'transfer') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_account_id) REFERENCES Account(account_id),
    FOREIGN KEY (receiver_account_id) REFERENCES Account(account_id)
);

-- =====================
-- 5. AUDIT LOG TABLE
-- =====================
CREATE TABLE AuditLog (
    log_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    performed_by VARCHAR(100),
    activity VARCHAR(100),
    details TEXT,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================
-- 6. ADMIN TABLE
-- =====================
CREATE TABLE Admin (
    admin_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    position ENUM('superadmin', 'staff') DEFAULT 'staff',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- STORED PROCEDURES & FUNCTIONS BELOW
-- ========================================
-- Includes: deposit, withdraw, transfer
-- And utility functions: get_balance, get_account_status, etc.

-- Each procedure/function should be separated using DELIMITER
-- and DROP IF EXISTS for clean redefinition

-- INSERT sample data & CALL procedures
-- Refer to original script for sample INSERTs and CALLs

-- ====================
-- PROCEDURES
-- ====================


-- ====================
-- 1. DEPOSIT
-- ====================


CREATE PROCEDURE deposit(IN acc_id INT, IN amt DECIMAL(12,2))
BEGIN
    IF amt > 0 THEN
        -- Update account balance
        UPDATE Account SET balance = balance + amt WHERE account_id = acc_id;

        -- Insert into Transaction
        INSERT INTO Transaction (receiver_account_id, amount, transaction_type)
        VALUES (acc_id, amt, 'deposit');

        -- Insert into AuditLog
        INSERT INTO AuditLog (performed_by, activity, details)
        VALUES (
            CONCAT('Account ID ', acc_id),
            'Deposit',
            CONCAT('Deposited ₹', amt, ' into account ID ', acc_id)
        );

    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deposit amount must be positive';
    END IF;
END //

-- ====================
-- 2. WITHDRAW
-- ====================
CREATE PROCEDURE withdraw(IN acc_id INT, IN amt DECIMAL(12,2))
BEGIN
    DECLARE curr_balance DECIMAL(12,2);

    SELECT balance INTO curr_balance FROM Account WHERE account_id = acc_id;

    IF curr_balance >= amt THEN
        -- Update account balance
        UPDATE Account SET balance = balance - amt WHERE account_id = acc_id;

        -- Record the withdrawal in Transaction
        INSERT INTO Transaction (sender_account_id, amount, transaction_type)
        VALUES (acc_id, amt, 'withdrawal');

        -- Log the action in AuditLog
        INSERT INTO AuditLog (performed_by, activity, details)
        VALUES (
            CONCAT('Account ID ', acc_id),
            'Withdrawal',
            CONCAT('Withdrew ₹', amt, ' from account ID ', acc_id)
        );

    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;
END //


-- ===================
-- 3. TRANSFER
-- ===================

CREATE PROCEDURE transfer(IN from_acc INT, IN to_acc INT, IN amt DECIMAL(12,2))
BEGIN
    DECLARE bal DECIMAL(12,2);

    SELECT balance INTO bal FROM Account WHERE account_id = from_acc;

    IF bal >= amt THEN
        -- Deduct from sender
        UPDATE Account SET balance = balance - amt WHERE account_id = from_acc;

        -- Credit to receiver
        UPDATE Account SET balance = balance + amt WHERE account_id = to_acc;

        -- Record in Transaction
        INSERT INTO Transaction (sender_account_id, receiver_account_id, amount, transaction_type)
        VALUES (from_acc, to_acc, amt, 'transfer');

        -- Log the transfer in AuditLog
        INSERT INTO AuditLog (performed_by, activity, details)
        VALUES (
            CONCAT('Account ID ', from_acc),
            'Transfer',
            CONCAT('Transferred ₹', amt, ' to Account ID ', to_acc)
        );

    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;
END //


-- =====================
-- FUNCTIONS
-- =====================


-- =====================
-- 1. GET_BALANCE
-- =====================

CREATE FUNCTION get_balance(acc_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE bal DECIMAL(12,2);
    SELECT balance INTO bal FROM Account WHERE account_id = acc_id;
    RETURN bal;
END //

-- =====================
-- 2. GET_ACCOUNT_STATUS
-- =====================

CREATE FUNCTION get_account_status(acc_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE acc_status VARCHAR(20);
    SELECT status INTO acc_status
    FROM Account
    WHERE account_id = acc_id;
    RETURN acc_status;
END //

-- =====================
-- 3. GET_LAST_TRANSACTION_TIME
-- =====================

CREATE FUNCTION get_last_transaction_time(acc_id INT)
RETURNS DATETIME
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE last_time DATETIME;
    SELECT MAX(timestamp)
    INTO last_time
    FROM Transaction
    WHERE sender_account_id = acc_id
       OR receiver_account_id = acc_id;
    RETURN last_time;
END //

-- =========================
-- 4. GET_TRANSACTION_COUNT
-- =========================

CREATE FUNCTION get_transaction_count(acc_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total INT;
    SELECT COUNT(*)
    INTO total
    FROM Transaction
    WHERE sender_account_id = acc_id
       OR receiver_account_id = acc_id;
    RETURN total;
END //

-- ===================================================
-- FEW INSTANCES OF  PROCEDURES AND FUNCTIONS
-- ===================================================

CALL deposit(1, 3000.00);
CALL transfer(7, 5000.00);
CALL deposit(2, 2500.00);
CALL withdraw(3, 4000.00);
CALL deposit(4, 1000.00);

SELECT get_balance(4) AS balance_acc_4;
SELECT get_account_status(1) AS status_acc_1;
SELECT get_transaction_count(4) AS txn_count;
SELECT get_last_transaction_time(5) AS last_txn_time;

-- HOW TO ADD ROWS IN THE CUSTOMER TABLE
INSERT INTO Customer (name, email, phone, address) VALUES
('Ananya Sharma', 'ananya.sharma@example.com', '9876512345', 'Bangalore, Karnataka'),
('Ravi Kumar', 'ravi.kumar@example.com', '9876523456', 'Chennai, Tamil Nadu'),
('Sunita Reddy', 'sunita.reddy@example.com', '9876534567', 'Hyderabad, Telangana'),
('Mohit Jain', 'mohit.jain@example.com', '9876545678', 'Delhi, India'),
('Priya Mehra', 'priya.mehra@example.com', '9876556789', 'Mumbai, Maharashtra');

-- HOW TO INSERT ACCOUNTS FOR THE NEW CUSTOMERS(assuming branch_id = 506004)
INSERT INTO Account (customer_id, account_type, balance, status, branch_id) VALUES
(15, 'savings', 8000.00, 'active', 506004),
(16, 'current', 12000.00, 'active', 506004),
(17, 'savings', 9500.00, 'active', 506004),
(18, 'current', 7200.00, 'active', 506004),
(19, 'savings', 8800.00, 'active', 506004);

-- ======================================
-- FEW INSTANCES OF QUERIES 
-- ======================================
-- Find Transactions for a Specific Account
SELECT transaction_id, transaction_date, sender_account_id, receiver_account_id, amount, transaction_type
FROM Transaction
WHERE sender_account_id = 201 OR receiver_account_id = 201
ORDER BY transaction_date DESC;

-- Check Account Balance by Account ID
SELECT balance
FROM Account
WHERE account_id = 201;


