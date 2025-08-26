;; Minimal Test Executive Dashboard for GnuCash
;; Diagnostic version to test basic report registration

(define-module (gnucash report executive-dashboard-test))

(use-modules (gnucash core-utils))
(use-modules (gnucash engine))
(use-modules (gnucash app-utils))
(use-modules (gnucash utilities))
(use-modules (gnucash report report-core))
(use-modules (gnucash report html-document))

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

;; Simple options generator for testing
(define (test-dashboard-options-generator)
  (let ((options (gnc-new-optiondb)))
    ;; Date range options
    (gnc:options-add-date-interval!
     options gnc:pagename-general "start-date" "end-date" "a")
    
    ;; Account selection
    (gnc-register-account-list-option options
      gnc:pagename-accounts "accounts" "a" "Select accounts to include"
      (gnc-account-get-descendants-sorted (gnc-get-current-root-account)))
    
    (GncOptionDBPtr-set-default-section options gnc:pagename-general)
    options))

;; Simple renderer for testing
(define (test-dashboard-renderer report-obj)
  (let ((document (gnc:make-html-document)))
    (gnc:html-document-set-title! document "Test Executive Dashboard")
    
    ;; Add simple test content
    (gnc:html-document-add-object! document
      (gnc:make-html-text 
        "<div style='padding: 20px; font-family: Arial, sans-serif;'>"
        "<h1>Test Executive Dashboard</h1>"
        "<p>If you can see this, the basic report registration is working!</p>"
        "<p>This is a diagnostic version to test GnuCash report loading.</p>"
        "</div>"))
    
    document))

;; Register the test report
(gnc:define-report
 'version 1
 'name "Test Executive Dashboard"
 'report-guid "test-exec-dash-1234-5678-90ab-cdef12345678"
 'menu-path (list gnc:menuname-experimental)
 'menu-name "Test Executive Dashboard"
 'menu-tip "Minimal test version of executive dashboard"
 'options-generator test-dashboard-options-generator
 'renderer test-dashboard-renderer)