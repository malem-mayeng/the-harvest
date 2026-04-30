# The Harvest V2 — Walkthrough

## Overview

Upgraded The Harvest from V1 to V2 with **9 feature additions**. All changes are **backwards-compatible** — existing data is preserved via SQLite migration (version 1→2).

## What Changed

### Database Migration (v1 → v2)
- **Sales table**: Added `notes TEXT` and `total_paid REAL` columns via `ALTER TABLE`
- **Existing data**: `total_paid` backfilled from `advance_paid` for all existing rows
- **New tables**: `payments` (transaction tracking) and `custom_items` (persisted item names)
- File: [database_helper.dart](file:///home/malem/the-harvest/app/lib/database/database_helper.dart) — `onUpgrade` handler

### Payment Tracking System (NEW)
- **New `payments` table** tracks individual payment transactions with date, amount, and notes
- **"Add Payment" button** on pending sale cards — records a payment, updates `total_paid` and `due_amount`
- **"Mark Complete" (Done) button** — settles the sale at current `total_paid`, sets due=0, with optional settlement notes
- **"₹ History" button** in buyer detail header — shows all transactions (advances + payments) chronologically
- Model: [payment.dart](file:///home/malem/the-harvest/app/lib/models/payment.dart)
- Screen: [payment_history_screen.dart](file:///home/malem/the-harvest/app/lib/screens/payment_history_screen.dart)

### Optional Quantity & Total Amount
- Both fields no longer require input — users can leave them blank for log-only entries
- When empty: stored as `0`, displayed as "—" on sale cards
- **Negative due prevention**: Due is always clamped to ≥0, even when advance > total

### Notes Field
- Multi-line text field added before the Save button in Add/Edit Sale
- Displayed as an italic snippet on sale cards

### Custom Item Persistence
- When "Other" is selected and a custom item name is entered, it's saved to `custom_items` table
- Next time the dropdown is opened, all previously-added items appear alongside Fish and Vegetables
- Resettable via Settings → "Reset Item List"

### Delete Sale
- Red delete icon on the right side of each sale card's action row
- Confirmation dialog → deletes associated payments then the sale

### Edit Sale — Buyer Name Fix
- In edit mode, the buyer name now shows as a **read-only grayed-out field** instead of an empty search box
- Buyer cannot be changed via edit (it's tied to the sale record)

### Buyer Edit/Delete
- **Edit**: Pencil icon on buyer card → dialog to rename
- **Delete**: Trash icon → Yes/No warning explaining all sales and payments will be deleted → cascade delete

### Settings Screen
- Gear icon in top-right corner of home screen
- **Reset Item List** — clears custom items, reverts to Fish + Vegetables defaults
- **Export Data** — placeholder ("Coming soon")
- **App version**: 2.0.0

## Files Changed

| Layer | Modified | New |
|-------|----------|-----|
| Database | `tables.dart`, `database_helper.dart` | — |
| Models | `sale.dart` | `payment.dart` |
| Repositories | `sale_repository.dart`, `buyer_repository.dart` | `payment_repository.dart`, `custom_item_repository.dart` |
| Services | `sale_service.dart`, `buyer_service.dart` | `custom_item_service.dart` |
| Providers | `providers.dart` | — |
| Widgets | `sale_card.dart` | — |
| Screens | `add_sale_screen.dart`, `buyer_detail_screen.dart`, `pending_payments_screen.dart`, `buyers_screen.dart`, `home_screen.dart` | `settings_screen.dart`, `payment_history_screen.dart` |

## Verification

- ✅ `flutter analyze` — No issues found
- ✅ `flutter build apk --release` — Built successfully (21.6MB)
- APK location: `build/app/outputs/flutter-apk/app-release.apk`

## Install & Upgrade

The new APK can be installed **directly over the existing V1 app** — the SQLite migration runs automatically on first launch, preserving all existing buyers and sales data.
