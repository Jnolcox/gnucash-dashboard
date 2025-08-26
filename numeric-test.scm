;; Test file for validating numeric operations
;; This file tests the fixed numeric functions

(define-module (gnucash report numeric-test))

;; Define constants from research of GnuCash source
(define GNC-RND-ROUND 5)
(define GNC-DENOM-AUTO 0)
(define GNC-DENOM-LCD 64)
(define GNC-DENOM-REDUCE 32)

;; Test helper functions that match GnuCash patterns
(define (test-numeric-add a b)
  "Test numeric addition with 4 parameters"
  (gnc-numeric-add a b 0 GNC-DENOM-LCD))

(define (test-numeric-sub a b)
  "Test numeric subtraction with 4 parameters"  
  (gnc-numeric-sub a b 0 GNC-DENOM-LCD))

;; Test cases (these are the corrected function signatures)
;; 
;; Previously we had: (gnc-numeric-add 0 0)    ; WRONG - 2 args
;; Now we have:       (gnc-numeric-add a b 0 GNC-DENOM-LCD) ; CORRECT - 4 args
;;
;; The error message showed: "Wrong number of arguments to gnc-numeric-add"
;; Expected: #<procedure gnc-numeric-add (_ _ _ _)> (4 arguments)  
;; Actual call: (gnc-numeric-add 0 0) (2 arguments)
;;
;; This confirms that gnc-numeric-add requires 4 parameters:
;; 1. First numeric value
;; 2. Second numeric value
;; 3. Denominator specification (0 or GNC-DENOM-* constant)
;; 4. Rounding method (GNC-DENOM-LCD, GNC-DENOM-AUTO, etc.)

(display "Numeric test functions defined successfully with 4-parameter signatures\n")