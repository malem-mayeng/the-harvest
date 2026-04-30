# Offline Android Farmer Sales Record App (Flutter APK)

Build a **real Android mobile application (APK)** using **Flutter**.

This must be an **actual installable Android APK**, not a web app, not a responsive webpage, and not a PWA.

The app is intended for **elderly farmers**, so simplicity is the highest priority.

---

# Primary Goal

The app helps a farmer record sales made to buyers and track pending payments.

The app must work fully **offline**.

No internet should be required for normal use.

---

# Core Technical Requirements

Use:

- Flutter
- SQLite local database
- Repository pattern
- Service layer for business logic
- Simple clean Flutter architecture

Recommended packages:

- sqflite
- riverpod

Alternative acceptable:

- drift
- provider

---

# Important Architecture Rule

Do NOT design this as:

Frontend + remote backend + cloud database

Design this as:

Flutter UI → Local Service Layer → SQLite Database

All business logic must run locally inside the app.

No external backend required.

---

# Main User Type

Primary users are elderly farmers who may have:

- limited smartphone experience
- slow reading speed
- low digital literacy

Therefore UI must prioritize:

- large text
- large buttons
- very simple navigation
- minimal screens
- very few actions per screen
- strong contrast
- clear labels
- no clutter

---

# Before Generating Code

First propose:

1. Folder structure
2. Database schema
3. Navigation flow
4. Screen list

Then generate code module by module.

Do NOT generate everything in one giant file.

Use production-grade clean code.

---

# App Core Screens

## 1. Home Screen

Show only 3 large buttons:

- Add Sale
- Buyers
- Pending Payments

Requirements:

- vertically stacked large buttons
- easy one-hand use
- minimal text

---

## 2. Add Sale Screen

When adding a sale:

Fields:

- Buyer Name
- Date
- Item Sold
- Unit Type
- Quantity
- Total Amount
- Advance Paid
- Due Amount
- Status

---

## Buyer Name Logic

When typing buyer name:

- search existing buyers first
- suggest existing buyers
- if not found, allow adding new buyer

Buyer must have:

- name
- auto generated unique buyer code

Example:

- B001
- B002

---

## Date Logic

- default today's date
- editable manually
- timezone IST only

---

## Item Logic

Pre-listed items:

- Fish
- Vegetables

Also:

- Other (custom item input allowed)

---

## Unit Type

Options:

- Count
- Weight

---

## Amount Logic

Fields:

- Total Amount
- Advance Paid

Automatically calculate:

Due Amount = Total Amount - Advance Paid

---

## Status Options

- Pending
- Paid

---

## Buttons

- Save Record
- Cancel

---

## UX Requirements

- numeric keypad for amount entry
- dropdowns where possible
- auto move logically between fields

---

# 3. Buyer Screen

Selecting a buyer shows:

- Buyer Name
- Buyer Code
- All records under that buyer

Each record shows:

- Date
- Item
- Quantity
- Total Amount
- Advance Paid
- Due Amount
- Status

Actions:

- Edit record
- Mark fully paid

---

## Payment Completion Rule

When marked paid:

- due amount becomes 0
- status changes to paid

---

# 4. Pending Payments Screen

Show only unpaid records.

Each row shows:

- Buyer Name
- Item
- Due Amount
- Date

Quick action:

- Mark Paid

---

# Data Storage Design

Use SQLite.

---

## Buyer Table

Fields:

- id (primary key auto increment)
- buyer_code (unique)
- buyer_name
- created_at

---

## Sales Table

Fields:

- id
- buyer_id
- item_name
- unit_type
- quantity
- total_amount
- advance_paid
- due_amount
- sale_date
- status
- created_at
- updated_at

---

# Business Rules

## Add Sale

- buyer selected or created
- today's date auto selected

## Edit Record

- editable anytime

## Payment Update

- marking paid updates due to zero

---

# State Management

Recommended:

- Riverpod

Keep state simple and maintainable.

---

# Folder Structure

Use:

lib/
  models/
  database/
  repositories/
  services/
  screens/
  widgets/

---

# Performance Requirement

Must run smoothly on:

- low-end Android phones
- older Android devices

Keep dependencies minimal.

---

# Offline First Requirement

App must fully work without:

- internet
- login
- cloud sync

Nothing should fail offline.

---

# Future Extensibility (prepare architecture only)

Keep architecture ready for later adding:

- CSV export
- Excel export
- Gmail backup
- cloud sync

Do not implement now.

---

# UX Design Style

Design must feel:

- practical
- rural-friendly
- trustworthy
- lightweight
- easy for age 50+

---

# Important Final Instruction

Generate:

- compile-ready Flutter code
- APK-ready project
- clean architecture
- reusable widgets

Proceed step by step.