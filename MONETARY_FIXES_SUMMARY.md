# GnuCash Dashboard Monetary Function Fixes

## Problem Summary

The simplified and core dashboards were failing with the error:
```
Unbound variable: gnc:monetary-list-display-string
```

## Root Cause Analysis

1. **Incorrect Function Name**: The code was using `gnc:monetary-list-display-string` which doesn't exist in the GnuCash API
2. **Wrong Monetary Constructor**: The code was using `gnc:make-commodity-monetary` which doesn't exist
3. **Missing Import**: The correct functions are exported from `(gnucash report report-utilities)` which was imported correctly

## Research Process

1. **Located GnuCash Installation**: Found GnuCash Scheme files at `/Applications/Gnucash.app/Contents/Resources/share/guile/site/2.2/gnucash/`
2. **Analyzed report-utilities.scm**: Found the correct function `gnc:monetary->string` at line 131
3. **Verified Function Usage**: Found widespread usage of `gnc:make-gnc-monetary` in official reports
4. **Confirmed Currency Function**: Verified `gnc-default-report-currency` exists and is used throughout

## Correct Functions Identified

| Incorrect Function | Correct Function | Purpose |
|-------------------|------------------|---------|
| `gnc:monetary-list-display-string` | `gnc:monetary->string` | Display monetary values as formatted strings |
| `gnc:make-commodity-monetary` | `gnc:make-gnc-monetary` | Create monetary objects from commodity and amount |
| `(gnc-default-report-currency)` | ✓ Correct | Get default report currency |

## Files Fixed

### 1. executive-dashboard-simplified.scm
- Fixed 3 instances in KPI card display (lines 202, 211, 220)
- **Before**: `(gnc:monetary-list-display-string (list (gnc:make-commodity-monetary (gnc-default-report-currency) value)) #f)`
- **After**: `(gnc:monetary->string (gnc:make-gnc-monetary (gnc-default-report-currency) value))`

### 2. executive-dashboard-core.scm
- Fixed 5 instances across the file:
  - Account breakdown display (line 228)
  - Net Worth KPI (line 344)
  - Total Assets KPI (line 354)  
  - Total Liabilities KPI (line 364)
  - Emergency Fund KPI (line 375)

## Function Usage Pattern

The correct pattern for displaying monetary values in GnuCash reports:

```scheme
;; Create a monetary object
(define monetary-obj (gnc:make-gnc-monetary currency numeric-amount))

;; Display as formatted string
(define display-string (gnc:monetary->string monetary-obj))
```

## Testing

Created `monetary-test.scm` to verify the functions work correctly:
- Tests `gnc:make-gnc-monetary` creation
- Tests `gnc:monetary->string` formatting
- Provides visual confirmation in GnuCash reports menu

## Validation

The fixes were validated by:
1. **API Research**: Confirmed functions exist in GnuCash source code
2. **Usage Verification**: Found extensive usage in official GnuCash reports
3. **Pattern Matching**: Followed established patterns from existing reports
4. **Test Creation**: Built verification test report

## Expected Outcome

After these fixes:
- ✅ Dashboard reports should load without "Unbound variable" errors
- ✅ Monetary values should display with proper currency formatting
- ✅ All KPI cards should show formatted amounts (e.g., "$1,234.56")
- ✅ Account breakdowns should display balances correctly

## Next Steps

1. **Test the Reports**: Load GnuCash and run both simplified and core dashboards
2. **Verify Display**: Confirm monetary values appear correctly formatted
3. **Performance Check**: Ensure no performance regressions from the fixes
4. **Documentation Update**: Update any user documentation if needed

## Technical Notes

- All fixes maintain the same functionality, only correcting API calls
- No business logic changes were made
- The fixes follow GnuCash's established coding patterns
- Import statements were already correct (`(gnucash report report-utilities)` was imported)

---

*Fixed on 2025-08-26 by Claude Code*