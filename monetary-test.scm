;; Test script to verify monetary display functions work
;; This script tests the corrected monetary display functionality

(define-module (gnucash report monetary-test))

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

;; Test function to verify monetary display works
(define (test-monetary-functions)
  "Test the corrected monetary display functions"
  (let* ((default-currency (gnc-default-report-currency))
         (test-amount (gnc-numeric-create 12345 100))  ; $123.45
         (monetary-obj (gnc:make-gnc-monetary default-currency test-amount))
         (display-string (gnc:monetary->string monetary-obj)))
    
    ;; Print test results
    (display "=== Monetary Function Test ===\n")
    (display "Default Currency: ")
    (display (gnc-commodity-get-mnemonic default-currency))
    (display "\n")
    (display "Test Amount: ")
    (display (gnc-numeric-to-double test-amount))
    (display "\n")
    (display "Formatted Display: ")
    (display display-string)
    (display "\n")
    (display "Test Status: SUCCESS - No errors!\n")
    (display "===============================\n")
    
    ;; Return success status
    #t))

;; Main test renderer
(define (monetary-test-renderer report-obj)
  "Simple test report to verify monetary functions work"
  (let ((document (gnc:make-html-document)))
    
    (gnc:html-document-set-title! document "Monetary Function Test")
    
    ;; Test the functions and capture any errors
    (catch #t
      (lambda ()
        (test-monetary-functions)
        (gnc:html-document-add-object! document
          (gnc:make-html-text 
            "<h1>Monetary Function Test</h1>"
            "<p style='color: green; font-weight: bold;'>✓ SUCCESS: All monetary functions working correctly!</p>"
            "<p>The gnc:monetary->string and gnc:make-gnc-monetary functions are properly accessible.</p>"
            "<p>Dashboard reports should now display monetary values without errors.</p>")))
      (lambda (key . args)
        (gnc:html-document-add-object! document
          (gnc:make-html-text 
            "<h1>Monetary Function Test</h1>"
            "<p style='color: red; font-weight: bold;'>✗ ERROR: Test failed</p>"
            "<p>Error: " (format #f "~a" key) "</p>"
            "<p>Details: " (format #f "~a" args) "</p>"))))
    
    document))

;; Test options (minimal)
(define (monetary-test-options-generator)
  (let ((options (gnc-new-optiondb)))
    (GncOptionDBPtr-set-default-section options gnc:pagename-general)
    options))

;; Register the test report
(gnc:define-report
 'version 1
 'name "Monetary Function Test"
 'report-guid "monetary-test-2024-1234-5678-90abcdef1234"
 'menu-path (list gnc:menuname-experimental)
 'menu-name "Monetary Function Test"
 'menu-tip "Test monetary display functions"
 'options-generator monetary-test-options-generator
 'renderer monetary-test-renderer)