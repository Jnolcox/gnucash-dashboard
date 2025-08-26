;; Simplified Executive Financial Dashboard for GnuCash
;; This version removes complex optimizations to test basic functionality

(define-module (gnucash report executive-dashboard-simplified))

(use-modules (gnucash core-utils))
(use-modules (gnucash engine))
(use-modules (gnucash app-utils))
(use-modules (gnucash utilities))
(use-modules (gnucash report report-core)
             (gnucash report report-utilities)
             (gnucash report options-utilities)
             (gnucash report commodity-utilities)
             (gnucash report html-document)
             (gnucash report html-style-info)
             (gnucash report html-utilities)
             (gnucash report html-table)
             (gnucash report html-text))
(use-modules (srfi srfi-1))
(use-modules (ice-9 format))

;; Define account type constants (compatible with all GnuCash versions)
(define ACCT-TYPE-ASSET 2)
(define ACCT-TYPE-BANK 1)
(define ACCT-TYPE-CASH 3)
(define ACCT-TYPE-STOCK 5)
(define ACCT-TYPE-MUTUAL 6)
(define ACCT-TYPE-INVESTMENT 5) ; Same as STOCK
(define ACCT-TYPE-LIABILITY 8)
(define ACCT-TYPE-CREDIT 9)
(define ACCT-TYPE-PAYABLE 10)
(define ACCT-TYPE-EXPENSE 12)
(define ACCT-TYPE-INCOME 11)

;; Define additional GnuCash constants
(define gnc:denom-auto 0)
(define GNC-RND-ROUND 5)
(define GNC-DENOM-AUTO 0)
(define GNC-DENOM-LCD 64)
(define GNC-DENOM-REDUCE 32)

;; Safe numeric addition helper (following GnuCash patterns)
(define (safe-numeric-add a b)
  "Safely add two gnc-numeric values"
  (gnc-numeric-add a b 0 GNC-DENOM-LCD))

;; Safe numeric subtraction helper  
(define (safe-numeric-sub a b)
  "Safely subtract two gnc-numeric values"
  (gnc-numeric-sub a b 0 GNC-DENOM-LCD))

;; Basic utility functions
(define (get-account-balance account start-date end-date)
  "Get balance for account over date range"
  (let* ((balance (xaccAccountGetBalanceAsOfDate account end-date))
         (start-balance (xaccAccountGetBalanceAsOfDate account start-date)))
    (safe-numeric-sub balance start-balance)))

(define (find-accounts-by-type root-account account-types)
  "Find all accounts of specified types under root account"
  (filter (lambda (account)
            (member (xaccAccountGetType account) account-types))
          (gnc-account-get-descendants-sorted root-account)))

;; HTML utility functions
(define (create-dashboard-styles)
  "Create CSS styles for the dashboard"
  "<style>
    .dashboard-container { 
      max-width: 1200px; 
      margin: 0 auto; 
      padding: 20px; 
      font-family: Arial, sans-serif; 
    }
    .kpi-grid { 
      display: grid; 
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); 
      gap: 20px; 
      margin-bottom: 30px; 
    }
    .kpi-card { 
      background: #f8fafc; 
      border: 1px solid #e2e8f0; 
      border-radius: 8px; 
      padding: 20px; 
      text-align: center; 
    }
    .kpi-value { 
      font-size: 24px; 
      font-weight: bold; 
      color: #1e40af; 
      margin: 10px 0; 
    }
    .kpi-label { 
      font-size: 14px; 
      color: #64748b; 
      margin-bottom: 5px; 
    }
    .section { 
      margin: 30px 0; 
      padding: 20px; 
      background: white; 
      border: 1px solid #e2e8f0; 
      border-radius: 8px; 
    }
    .section-title { 
      font-size: 18px; 
      font-weight: bold; 
      margin-bottom: 15px; 
      color: #1e40af; 
    }
  </style>")

(define (create-kpi-card title value description)
  "Create a KPI card HTML"
  (string-append
    "<div class='kpi-card'>"
    "<div class='kpi-label'>" title "</div>"
    "<div class='kpi-value'>" value "</div>"
    "<div style='font-size: 12px; color: #64748b;'>" description "</div>"
    "</div>"))

;; Report Options
(define (simplified-dashboard-options-generator)
  (let ((options (gnc-new-optiondb)))
    
    ;; Date range options
    (gnc:options-add-date-interval!
     options gnc:pagename-general "start-date" "end-date" "a")
    
    ;; Account selection
    (gnc-register-account-list-option options
      gnc:pagename-accounts "accounts" "a" "Select accounts to include"
      (gnc-account-get-descendants-sorted (gnc-get-current-root-account)))
    
    ;; Simple display options
    (gnc-register-simple-boolean-option options
      gnc:pagename-display "show-charts" "a" "Display visual elements" #t)
    
    (GncOptionDBPtr-set-default-section options gnc:pagename-general)
    options))

;; Main Renderer Function
(define (simplified-dashboard-renderer report-obj)
  (let* ((options (gnc:report-options report-obj))
         (start-date (gnc:date-option-absolute-time 
                     (gnc-optiondb-lookup-value options gnc:pagename-general "start-date")))
         (end-date (gnc:date-option-absolute-time 
                   (gnc-optiondb-lookup-value options gnc:pagename-general "end-date")))
         (accounts (or (gnc-optiondb-lookup-value options gnc:pagename-accounts "accounts")
                       (gnc-account-get-descendants-sorted (gnc-get-current-root-account))))
         (root-account (gnc-get-current-root-account))
         (document (gnc:make-html-document)))
    
    (gnc:html-document-set-title! document "Executive Dashboard (Simplified)")
    
    ;; Add CSS styles
    (gnc:html-document-add-object! document
      (gnc:make-html-text (create-dashboard-styles)))
    
    ;; Start dashboard container
    (gnc:html-document-add-object! document
      (gnc:make-html-text "<div class='dashboard-container'>"))
    
    ;; Header
    (gnc:html-document-add-object! document
      (gnc:make-html-text 
        "<h1>Executive Financial Dashboard</h1>"
        "<p>Simplified version - " 
        (strftime "%B %d, %Y" (localtime (current-time)))
        "</p>"))
    
    ;; KPI Cards Section
    (gnc:html-document-add-object! document
      (gnc:make-html-text "<div class='kpi-grid'>"))
    
    ;; Calculate basic metrics
    (let* ((asset-accounts (find-accounts-by-type root-account 
                                                  (list ACCT-TYPE-ASSET ACCT-TYPE-BANK 
                                                        ACCT-TYPE-CASH ACCT-TYPE-STOCK
                                                        ACCT-TYPE-MUTUAL ACCT-TYPE-INVESTMENT)))
           (liability-accounts (find-accounts-by-type root-account 
                                                      (list ACCT-TYPE-LIABILITY 
                                                            ACCT-TYPE-CREDIT ACCT-TYPE-PAYABLE)))
           (total-assets (fold (lambda (acc sum)
                              (safe-numeric-add sum 
                                              (xaccAccountGetBalanceAsOfDate acc end-date)))
                            (gnc-numeric-zero)
                            asset-accounts))
           (total-liabilities (fold (lambda (acc sum)
                                   (safe-numeric-add sum 
                                                   (gnc-numeric-neg 
                                                    (xaccAccountGetBalanceAsOfDate acc end-date))))
                                 (gnc-numeric-zero)
                                 liability-accounts))
           (net-worth (safe-numeric-sub total-assets total-liabilities)))
      
      ;; Net Worth KPI
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Net Worth" 
                          (gnc:monetary->string
                           (gnc:make-gnc-monetary 
                            (gnc-default-report-currency) net-worth))
                          "Total assets minus liabilities")))
      
      ;; Total Assets KPI
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Total Assets" 
                          (gnc:monetary->string
                           (gnc:make-gnc-monetary 
                            (gnc-default-report-currency) total-assets))
                          "All asset accounts")))
      
      ;; Total Liabilities KPI  
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Total Liabilities" 
                          (gnc:monetary->string
                           (gnc:make-gnc-monetary 
                            (gnc-default-report-currency) total-liabilities))
                          "All liability accounts")))
      
      ;; Account Count KPI
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Active Accounts" 
                          (number->string (length accounts))
                          "Total accounts being tracked"))))
    
    ;; Close KPI grid
    (gnc:html-document-add-object! document
      (gnc:make-html-text "</div>"))
    
    ;; Account Summary Section
    (gnc:html-document-add-object! document
      (gnc:make-html-text 
        "<div class='section'>"
        "<div class='section-title'>Account Summary</div>"
        "<p>This simplified dashboard shows basic financial metrics.</p>"
        "<p>Date Range: " (strftime "%Y-%m-%d" (localtime start-date)) 
        " to " (strftime "%Y-%m-%d" (localtime end-date)) "</p>"
        "<p>Total Accounts: " (number->string (length accounts)) "</p>"
        "</div>"))
    
    ;; Close dashboard container
    (gnc:html-document-add-object! document
      (gnc:make-html-text "</div>"))
    
    document))

;; Register the Report
(gnc:define-report
 'version 1
 'name "Executive Dashboard (Simplified)"
 'report-guid "simple-exec-dash-2024-1234-5678-90abcdef1234"
 'menu-path (list gnc:menuname-experimental)
 'menu-name "Executive Dashboard (Simplified)"
 'menu-tip "Simplified executive financial dashboard for testing"
 'options-generator simplified-dashboard-options-generator
 'renderer simplified-dashboard-renderer)