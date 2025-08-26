#!/usr/bin/env guile
!#
;; Simple parentheses balance checker

(use-modules (ice-9 rdelim))

(define (check-parens filename)
  (call-with-input-file filename
    (lambda (port)
      (let loop ((line-num 1) (open-count 0) (in-string #f) (escape-next #f))
        (let ((char (read-char port)))
          (cond
           ((eof-object? char)
            (format #t "Final balance: ~a~%" open-count)
            (if (= open-count 0)
                (format #t "BALANCED~%")
                (format #t "UNBALANCED: ~a extra opening parens~%" open-count)))
           ((and escape-next (not (eof-object? char)))
            (loop line-num open-count in-string #f))
           ((char=? char #\\)
            (loop line-num open-count in-string #t))
           ((and (not in-string) (char=? char #\"))
            (loop line-num open-count #t #f))
           ((and in-string (char=? char #\"))
            (loop line-num open-count #f #f))
           ((and (not in-string) (char=? char #\;))
            ;; Skip to end of line for comment
            (let skip-comment ()
              (let ((c (read-char port)))
                (cond
                 ((eof-object? c) (loop (+ line-num 1) open-count #f #f))
                 ((char=? c #\newline) (loop (+ line-num 1) open-count #f #f))
                 (else (skip-comment))))))
           ((and (not in-string) (char=? char #\())
            (loop line-num (+ open-count 1) #f #f))
           ((and (not in-string) (char=? char #\)))
            (let ((new-count (- open-count 1)))
              (when (< new-count 0)
                (format #t "Line ~a: Extra closing paren~%" line-num))
              (loop line-num new-count #f #f)))
           ((char=? char #\newline)
            (loop (+ line-num 1) open-count in-string #f))
           (else
            (loop line-num open-count in-string #f))))))))

(check-parens "/Users/jnmbp/Engineering/GnuCash Dashboard/executive-dashboard.scm")