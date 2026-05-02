# The Harvest V2 — Feature Updates (Revised)

## Data Safety

> [!IMPORTANT]
> **All changes are backwards-compatible.** The existing SQLite database will be migrated in-place using `ALTER TABLE` + new tables (version 1 → 2). No data loss, no fresh install required. Existing records keep their data; new nullable columns default to `NULL`, new numeric columns default to `0`.

---

## Payment Tracking — Data Model

This is the biggest structural addition in V2. Here's the mental model:

```
Sale created:   total=10,000  advance=5,000  total_paid=5,000  due=5,000
Payment +3,000: total=10,000  advance=5,000  total_paid=8,000  due=2,000
Payment +1,500: total=10,000  advance=5,000  total_paid=9,500  due=500
Mark Complete:  total=10,000  advance=5,000  total_paid=9,500  due=0  status=paid
```

**Key rules:**
- `advance_paid` is set once at sale creation — **never changes**
- `total_paid` = `advance_paid` + sum of all subsequent payments
- `due_amount` = `total_amount` - `total_paid` (clamped to 0)
- `total_paid` is **non-editable** in the UI (auto-computed)
- "Add Payment" creates a row in the `payments` table and updates `total_paid` / `due_amount` on the sale
- "Mark Complete" sets `due_amount = 0`, `status = 'paid'` — settles at whatever `total_paid` is

**New `payments` table:**
```sql
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  payment_date TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
)
```

**Sales table additions (ALTER TABLE):**
- `total_paid REAL NOT NULL DEFAULT 0` — for existing rows, migration sets `total_paid = advance_paid`
- `notes TEXT` — nullable

---

## Proposed Changes

### 1. Make Quantity & Total Amount Optional + Handle Negative Due

**Form changes:**
- Remove mandatory validation from `quantity` and `total_amount`
- When `quantity` is empty → stored as `0`, displayed as "—" on sale cards
- When `total_amount` is empty → stored as `0`
- **Negative due handling:** If `advance_paid > total_amount` (or total is 0 but advance has a value), clamp `due_amount` to `0`. The advance is simply recorded as-is — no negative due shown anywhere.

**Display:** Sale card shows "—" for quantity when 0, and shows "₹0" for total when 0 (the record still serves as a log entry with notes).

---

### 2. Payment Tracking & Mark Complete

#### Add Payment Button (on Sale Cards)
- A new **"Add Payment"** button appears on pending sale cards (alongside Edit)
- Opens a dialog with:
  - Current due amount shown (read-only)
  - Amount field (pre-filled with due amount, editable)
  - Optional notes field
  - Date (defaults to today)
- Creates a `payment` record, updates `total_paid` and `due_amount` on the sale
- If the new `due_amount ≤ 0`, auto-marks the sale as `paid`

#### Mark Complete (in Pending Payments & Buyer Detail)
- Shows a confirmation dialog: *"Settle this sale? Current due: ₹X. This will mark the sale as fully paid."*
- Optional notes field for reason (e.g., "Forgave ₹500")
- Sets `due_amount = 0`, `status = 'paid'` — does NOT change `total_paid`

#### Payment History (in Buyer Detail Screen)
- In the buyer info header area (right side of name/code), add a **"₹ History"** button
- Opens a screen/bottom sheet showing **all payment transactions** for this buyer's sales, newest first
- Each entry shows: date, amount, sale item reference, notes
- Source data: the `payments` table + the initial `advance_paid` from each sale (displayed as the first "payment")

---

### 3. Notes Field on Add/Edit Sale

- Multi-line text field placed just before the Save button
- Label: "Notes (optional)"
- Hint: "e.g., Mixed veg — cabbage, beans, carrots"
- Stored in `notes TEXT` column

---

### 4. Persist Custom "Others" Item Names

**New table:** `custom_items (id, item_name, created_at)`

**Logic:**
- When saving a sale with "Other" selected, insert the custom name into `custom_items` (if not already present)
- Item dropdown is built dynamically: `['Fish', 'Vegetables'] + [custom items from DB] + ['Other']`
- Custom items appear in the dropdown on next use

---

### 5. Delete Sale (icon on sale card)

- Red delete icon button on the right side of the action row (edit left, delete right)
- Confirmation: *"Delete this sale record? This cannot be undone."* — **Yes/No** dialog
- Deletes associated payments first, then the sale record
- Refreshes providers

---

### 6. Fix Buyer Name on Edit Sale Screen

- In edit mode: show buyer name in a **read-only, grayed-out field** — not the search widget
- `BuyerSearchField` is only shown in "Add" mode

---

### 7. Buyer Edit/Delete

**On the Buyers Screen — each buyer card gets Edit & Delete icons:**

**Edit Buyer:**
- Dialog with text field pre-filled with current name
- Updates `buyer_name` in the DB

**Delete Buyer:**
- **Simple Yes/No warning**: *"⚠️ Delete [Name]? This will permanently delete ALL sales and payment records for this buyer. This cannot be undone."*
- Deletes: payments → sales → buyer (in transaction)

---

### 8. Settings Screen (Minimal Stub)

- Gear icon in top-right of Home screen
- Options:
  - **Reset Item List** — clears `custom_items` table, returns dropdown to defaults
  - **App version** display
- Future: export, etc.

---

## File Changes Summary

### Database Layer

#### [MODIFY] [database_helper.dart](file:///home/malem/the-harvest/app/lib/database/database_helper.dart)
- Bump version 1 → 2 with `onUpgrade` handler
- Migration:
  - `ALTER TABLE sales ADD COLUMN notes TEXT`
  - `ALTER TABLE sales ADD COLUMN total_paid REAL NOT NULL DEFAULT 0`
  - `UPDATE sales SET total_paid = advance_paid` (backfill existing rows)
  - `CREATE TABLE payments (...)`
  - `CREATE TABLE custom_items (...)`

#### [MODIFY] [tables.dart](file:///home/malem/the-harvest/app/lib/database/tables.dart)
- Update `createSalesTable` with `notes TEXT`, `total_paid REAL NOT NULL DEFAULT 0`
- Add `createPaymentsTable` and `createCustomItemsTable` SQL
- Add table name constants

---

### Models

#### [MODIFY] [sale.dart](file:///home/malem/the-harvest/app/lib/models/sale.dart)
- Add `notes` (String?) and `totalPaid` (double) fields
- Update `fromMap`, `toMap`, `copyWith`

#### [NEW] [payment.dart](file:///home/malem/the-harvest/app/lib/models/payment.dart)
- Fields: `id`, `saleId`, `amount`, `paymentDate`, `notes`, `createdAt`
- `fromMap`, `toMap`, `copyWith`

---

### Repositories

#### [MODIFY] [sale_repository.dart](file:///home/malem/the-harvest/app/lib/repositories/sale_repository.dart)
- Add `delete(int saleId)` method
- Add `deleteByBuyerId(int buyerId)` method
- Add `updatePaymentTotals(saleId, totalPaid, dueAmount, status)` method

#### [MODIFY] [buyer_repository.dart](file:///home/malem/the-harvest/app/lib/repositories/buyer_repository.dart)
- Add `updateName(int buyerId, String newName)` method
- Add `delete(int buyerId)` method

#### [NEW] [payment_repository.dart](file:///home/malem/the-harvest/app/lib/repositories/payment_repository.dart)
- `insert(Payment)`, `getBySaleId(saleId)`, `getByBuyerId(buyerId)`, `deleteBySaleId(saleId)`, `deleteBuyerPayments(buyerId)`

#### [NEW] [custom_item_repository.dart](file:///home/malem/the-harvest/app/lib/repositories/custom_item_repository.dart)
- `insert(name)`, `getAll()`, `deleteAll()`

---

### Services

#### [MODIFY] [sale_service.dart](file:///home/malem/the-harvest/app/lib/services/sale_service.dart)
- Update `createSale` / `editSale`: accept optional `notes`, optional `quantity` (default 0), optional `totalAmount` (default 0)
- Set `totalPaid = advancePaid` on creation
- Due amount clamped: `max(0, totalAmount - totalPaid)`
- Add `deleteSale(saleId)` — deletes payments first, then sale
- Add `markSaleAsComplete(saleId, notes)` — sets due=0, status=paid
- Add `addPayment(saleId, amount, notes, date)` — creates payment record, updates sale totals

#### [MODIFY] [buyer_service.dart](file:///home/malem/the-harvest/app/lib/services/buyer_service.dart)
- Add `updateBuyerName(buyerId, newName)`
- Add `deleteBuyerWithSales(buyerId)` — deletes payments → sales → buyer

#### [NEW] [custom_item_service.dart](file:///home/malem/the-harvest/app/lib/services/custom_item_service.dart)
- `addItem(name)`, `getAllItems()`, `resetToDefaults()`

---

### Providers

#### [MODIFY] [providers.dart](file:///home/malem/the-harvest/app/lib/providers/providers.dart)
- Add payment repository/service providers
- Add custom item repository/service/list providers
- Add `paymentHistoryProvider(buyerId)` — FutureProvider.family
- Add `salePaymentsProvider(saleId)` — FutureProvider.family

---

### Screens

#### [MODIFY] [add_sale_screen.dart](file:///home/malem/the-harvest/app/lib/screens/add_sale_screen.dart)
- Make quantity & total_amount optional (remove validators, handle 0)
- Clamp due to 0 when advance > total
- Add notes text field before Save button
- Dynamic item list from custom_items + defaults
- In edit mode: show buyer name as read-only grayed field

#### [MODIFY] [buyer_detail_screen.dart](file:///home/malem/the-harvest/app/lib/screens/buyer_detail_screen.dart)
- Pass `onDelete` callback to SaleCard
- Add "Add Payment" flow
- Add "₹ History" button in buyer header area
- Update Mark Complete with adjustment dialog

#### [MODIFY] [pending_payments_screen.dart](file:///home/malem/the-harvest/app/lib/screens/pending_payments_screen.dart)
- Add "Add Payment" and "Mark Complete" flows (same dialogs)

#### [MODIFY] [buyers_screen.dart](file:///home/malem/the-harvest/app/lib/screens/buyers_screen.dart)
- Add edit/delete icons on buyer cards
- Edit name dialog
- Delete with Yes/No confirmation + bold warning

#### [MODIFY] [home_screen.dart](file:///home/malem/the-harvest/app/lib/screens/home_screen.dart)
- Add Settings gear icon in top-right corner

#### [NEW] [settings_screen.dart](file:///home/malem/the-harvest/app/lib/screens/settings_screen.dart)
- Reset Item List option
- App version info display

#### [NEW] [payment_history_screen.dart](file:///home/malem/the-harvest/app/lib/screens/payment_history_screen.dart)
- Shows all payment transactions for a buyer, newest first
- Each entry: date, amount, related sale item, notes
- Advance payments shown as initial entries

---

### Widgets

#### [MODIFY] [sale_card.dart](file:///home/malem/the-harvest/app/lib/widgets/sale_card.dart)
- Add `onDelete` and `onAddPayment` callbacks
- Delete icon (red, right side)
- "Add Payment" button for pending sales
- Display "—" for quantity when 0
- Show `total_paid` alongside total/advance/due
- Show notes snippet if present

---

## Verification Plan

### Automated Tests
- `flutter analyze` — no lint errors
- `flutter build apk --release` — build succeeds

### Manual Verification
- Install new APK over existing app → verify data preserved
- Create a sale with empty quantity and total → verify no negative due
- Create a sale with advance but no total → verify due shows ₹0
- Add payments to a sale → verify total_paid increments, due decrements
- Mark complete → verify due=0, status=paid
- View payment history → verify entries with dates
- Add custom item via "Other" → verify it appears in dropdown next time
- Delete a sale → verify payments also deleted
- Edit/delete a buyer → verify cascade
- Settings → reset items → verify dropdown returns to defaults
