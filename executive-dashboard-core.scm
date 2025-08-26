;; Executive Financial Dashboard - Core Features
;; This version includes essential functionality without complex optimizations

(define-module (gnucash report executive-dashboard-core))

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
(use-modules (ice-9 regex))

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

(define (find-account-by-name-pattern root-account pattern)
  "Find account containing pattern in name (case insensitive)"
  (find (lambda (account)
          (let* ((account-name (xaccAccountGetName account))
                 (name-lower (string-downcase account-name))
                 (pattern-lower (string-downcase pattern)))
            (string-contains name-lower pattern-lower)))
        (gnc-account-get-descendants-sorted root-account)))

;; CSS Styles
(define (create-dashboard-styles)
  "Create CSS styles for the dashboard"
  "<style>
    .dashboard-container { 
      max-width: 1200px; 
      margin: 0 auto; 
      padding: 20px; 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      line-height: 1.6;
      color: #333;
    }
    .dashboard-header {
      text-align: center;
      margin-bottom: 30px;
      border-bottom: 2px solid #e2e8f0;
      padding-bottom: 20px;
    }
    .dashboard-title {
      font-size: 28px;
      font-weight: 700;
      color: #1e40af;
      margin-bottom: 5px;
    }
    .dashboard-subtitle {
      font-size: 16px;
      color: #64748b;
    }
    .kpi-grid { 
      display: grid; 
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); 
      gap: 20px; 
      margin-bottom: 40px; 
    }
    .kpi-card { 
      background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
      border: 1px solid #cbd5e1; 
      border-radius: 12px; 
      padding: 24px; 
      text-align: center;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
      transition: transform 0.2s ease-in-out;
    }
    .kpi-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 15px rgba(0, 0, 0, 0.1);
    }
    .kpi-value { 
      font-size: 32px; 
      font-weight: bold; 
      color: #1e40af; 
      margin: 15px 0; 
      font-family: 'Georgia', serif;
    }
    .kpi-label { 
      font-size: 14px; 
      color: #64748b; 
      margin-bottom: 8px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .kpi-description {
      font-size: 12px;
      color: #64748b;
      margin-top: 8px;
      font-style: italic;
    }
    .widget-section { 
      margin: 40px 0; 
      padding: 30px; 
      background: white; 
      border: 1px solid #e2e8f0; 
      border-radius: 12px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
    }
    .section-title { 
      font-size: 22px; 
      font-weight: bold; 
      margin-bottom: 20px; 
      color: #1e40af;
      border-bottom: 2px solid #3b82f6;
      padding-bottom: 8px;
    }
    .account-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 15px;
      margin-top: 20px;
    }
    .account-item {
      padding: 15px;
      background: #f8fafc;
      border-radius: 8px;
      border-left: 4px solid #3b82f6;
    }
    .account-name {
      font-weight: 600;
      color: #1e40af;
      margin-bottom: 5px;
    }
    .account-balance {
      font-size: 18px;
      font-weight: bold;
      color: #059669;
    }
    .positive { color: #059669; }
    .negative { color: #dc2626; }
    .neutral { color: #64748b; }
  </style>")

;; KPI Card creation
(define (create-kpi-card title value description trend-indicator)
  "Create a KPI card with optional trend indicator"
  (string-append
    "<div class='kpi-card'>"
    "<div class='kpi-label'>" title "</div>"
    "<div class='kpi-value'>" value "</div>"
    "<div class='kpi-description'>" description "</div>"
    (if trend-indicator 
        (string-append "<div style='margin-top: 10px; font-size: 14px;'>" trend-indicator "</div>")
        "")
    "</div>"))

;; Calculate net worth
(define (calculate-net-worth root-account end-date)
  "Calculate total net worth"
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
                                 liability-accounts)))
    (safe-numeric-sub total-assets total-liabilities)))

;; Create account breakdown
(define (create-account-breakdown accounts end-date title)
  "Create HTML for account breakdown"
  (let ((account-items
         (map (lambda (account)
                (let* ((balance (xaccAccountGetBalanceAsOfDate account end-date))
                       (balance-str (gnc:monetary->string
                                     (gnc:make-gnc-monetary 
                                      (gnc-default-report-currency) balance)))
                       (account-name (xaccAccountGetName account))
                       (balance-class (cond 
                                       ((gnc-numeric-positive-p balance) "positive")
                                       ((gnc-numeric-negative-p balance) "negative")
                                       (else "neutral"))))
                  (string-append
                    "<div class='account-item'>"
                    "<div class='account-name'>" account-name "</div>"
                    "<div class='account-balance " balance-class "'>" balance-str "</div>"
                    "</div>")))
              (take accounts (min 10 (length accounts))))))
    (string-append
      "<div class='widget-section'>"
      "<div class='section-title'>" title "</div>"
      "<div class='account-grid'>"
      (apply string-append account-items)
      "</div>"
      "</div>")))

;; Report Options
(define (core-dashboard-options-generator)
  (let ((options (gnc-new-optiondb)))
    
    ;; Date range options
    (gnc:options-add-date-interval!
     options gnc:pagename-general "start-date" "end-date" "a")
    
    ;; Account selection
    (gnc-register-account-list-option options
      gnc:pagename-accounts "accounts" "a" "Select accounts to include"
      (gnc-account-get-descendants-sorted (gnc-get-current-root-account)))
    
    ;; Display options
    (gnc-register-simple-boolean-option options
      gnc:pagename-display "show-breakdown" "a" "Show account breakdown sections" #t)
    
    (gnc-register-simple-boolean-option options
      gnc:pagename-display "show-trends" "b" "Show trend indicators in KPI cards" #t)
    
    (GncOptionDBPtr-set-default-section options gnc:pagename-general)
    options))

;; Main Renderer Function
(define (core-dashboard-renderer report-obj)
  (let* ((options (gnc:report-options report-obj))
         (start-date (gnc:date-option-absolute-time 
                     (gnc-optiondb-lookup-value options gnc:pagename-general "start-date")))
         (end-date (gnc:date-option-absolute-time 
                   (gnc-optiondb-lookup-value options gnc:pagename-general "end-date")))
         (accounts (or (gnc-optiondb-lookup-value options gnc:pagename-accounts "accounts")
                       (gnc-account-get-descendants-sorted (gnc-get-current-root-account))))
         (show-breakdown (gnc-optiondb-lookup-value options gnc:pagename-display "show-breakdown"))
         (show-trends (gnc-optiondb-lookup-value options gnc:pagename-display "show-trends"))
         (root-account (gnc-get-current-root-account))
         (document (gnc:make-html-document)))
    
    (gnc:html-document-set-title! document "Executive Financial Dashboard")
    
    ;; Add CSS styles
    (gnc:html-document-add-object! document
      (gnc:make-html-text (create-dashboard-styles)))
    
    ;; Start dashboard container
    (gnc:html-document-add-object! document
      (gnc:make-html-text "<div class='dashboard-container'>"))
    
    ;; Header
    (gnc:html-document-add-object! document
      (gnc:make-html-text 
        "<div class='dashboard-header'>"
        "<div class='dashboard-title'>Executive Financial Dashboard</div>"
        "<div class='dashboard-subtitle'>Core Financial Metrics - " 
        (strftime "%B %d, %Y" (localtime (current-time)))
        "</div>"
        "</div>"))
    
    ;; KPI Cards Section
    (gnc:html-document-add-object! document
      (gnc:make-html-text "<div class='kpi-grid'>"))
    
    ;; Calculate key metrics
    (let* ((asset-accounts (find-accounts-by-type root-account 
                                                  (list ACCT-TYPE-ASSET ACCT-TYPE-BANK 
                                                        ACCT-TYPE-CASH ACCT-TYPE-STOCK
                                                        ACCT-TYPE-MUTUAL ACCT-TYPE-INVESTMENT)))
           (liability-accounts (find-accounts-by-type root-account 
                                                      (list ACCT-TYPE-LIABILITY 
                                                            ACCT-TYPE-CREDIT ACCT-TYPE-PAYABLE)))
           (expense-accounts (find-accounts-by-type root-account 
                                                    (list ACCT-TYPE-EXPENSE)))
           (income-accounts (find-accounts-by-type root-account 
                                                   (list ACCT-TYPE-INCOME)))
           (net-worth (calculate-net-worth root-account end-date))
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
           (emergency-account (find-account-by-name-pattern root-account "Emergency"))
           (emergency-balance (if emergency-account
                                 (xaccAccountGetBalanceAsOfDate emergency-account end-date)
                                 (gnc-numeric-zero))))
      
      ;; Net Worth KPI
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Net Worth" 
                          (gnc:monetary->string
                           (gnc:make-gnc-monetary 
                            (gnc-default-report-currency) net-worth))
                          "Total assets minus liabilities"
                          (if show-trends "📈 Tracking wealth growth" #f))))
      
      ;; Total Assets KPI
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Total Assets" 
                          (gnc:monetary->string
                           (gnc:make-gnc-monetary 
                            (gnc-default-report-currency) total-assets))
                          "All asset accounts combined"
                          (if show-trends "💼 Investment portfolio" #f))))
      
      ;; Total Liabilities KPI  
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Total Liabilities" 
                          (gnc:monetary->string
                           (gnc:make-gnc-monetary 
                            (gnc-default-report-currency) total-liabilities))
                          "All outstanding debts"
                          (if show-trends "📉 Debt management" #f))))
      
      ;; Emergency Fund KPI
      (gnc:html-document-add-object! document
        (gnc:make-html-text 
          (create-kpi-card "Emergency Fund" 
                          (if emergency-account
                              (gnc:monetary->string
                               (gnc:make-gnc-monetary 
                                (gnc-default-report-currency) emergency-balance))
                              "Not Found")
                          (if emergency-account
                              "Funds for unexpected expenses"
                              "Create account with 'Emergency' in name")
                          (if show-trends 
                              (if emergency-account "🛡️ Financial safety net" "⚠️ Setup required")
                              #f)))))
    
    ;; Close KPI grid
    (gnc:html-document-add-object! document
      (gnc:make-html-text "</div>"))
    
    ;; Account Breakdown Sections
    (when show-breakdown
      (let* ((asset-accounts (find-accounts-by-type root-account 
                                                   (list ACCT-TYPE-ASSET ACCT-TYPE-BANK 
                                                         ACCT-TYPE-CASH ACCT-TYPE-STOCK
                                                         ACCT-TYPE-MUTUAL ACCT-TYPE-INVESTMENT)))
             (liability-accounts (find-accounts-by-type root-account 
                                                       (list ACCT-TYPE-LIABILITY 
                                                             ACCT-TYPE-CREDIT ACCT-TYPE-PAYABLE))))
        
        ;; Asset breakdown
        (when (not (null? asset-accounts))
          (gnc:html-document-add-object! document
            (gnc:make-html-text 
              (create-account-breakdown asset-accounts end-date "Asset Accounts"))))
        
        ;; Liability breakdown
        (when (not (null? liability-accounts))
          (gnc:html-document-add-object! document
            (gnc:make-html-text 
              (create-account-breakdown liability-accounts end-date "Liability Accounts"))))))
    
    ;; Summary Section
    (gnc:html-document-add-object! document
      (gnc:make-html-text 
        "<div class='widget-section'>"
        "<div class='section-title'>Dashboard Summary</div>"
        "<p>This executive dashboard provides core financial metrics for the period from " 
        (strftime "%Y-%m-%d" (localtime start-date)) 
        " to " (strftime "%Y-%m-%d" (localtime end-date)) ".</p>"
        "<p><strong>Total Accounts Tracked:</strong> " (number->string (length accounts)) "</p>"
        "<p><strong>Dashboard Features:</strong> Net worth tracking, asset/liability breakdown, emergency fund monitoring</p>"
        "<p><strong>Report Generated:</strong> " (strftime "%Y-%m-%d %H:%M:%S" (localtime (current-time))) "</p>"
        "</div>"))
    
    ;; Close dashboard container
    (gnc:html-document-add-object! document
      (gnc:make-html-text "</div>"))
    
    document))

;; Register the Report
(gnc:define-report
 'version 1
 'name "Executive Dashboard (Core)"
 'report-guid "core-exec-dash-2024-1234-5678-90abcdef1234"
 'menu-path (list gnc:menuname-experimental)
 'menu-name "Executive Dashboard (Core)"
 'menu-tip "Core executive financial dashboard with essential metrics"
 'options-generator core-dashboard-options-generator
 'renderer core-dashboard-renderer)