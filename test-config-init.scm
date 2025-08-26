;; Test configuration initialization
(define-module (test-config-init))

(use-modules (ice-9 format))

;; Dashboard Configuration - Centralized settings for customization
(define *dashboard-config*
  `((colors . ((primary . "#3b82f6")
               (success . "#10b981")))
    (logging . ((level . "INFO")
                (enable-debug . #f)))))

(define (config-get path)
  "Get configuration value by path (e.g., '(colors primary))"
  (let loop ((current *dashboard-config*) (remaining path))
    (cond 
     ((null? remaining) current)
     ((null? current) #f)
     ((not (pair? current)) #f)
     (else 
      (let ((value (assq (car remaining) current)))
        (if value
            (loop (cdr value) (cdr remaining))
            #f))))))

;; Log levels: DEBUG=0, INFO=1, WARN=2, ERROR=3
(define *log-levels* '((DEBUG . 0) (INFO . 1) (WARN . 2) (ERROR . 3)))

;; This was the problem - trying to initialize at module load time
(define *current-log-level* #f)

(define (log-message level format-str . args)
  "Log message with specified level"
  ;; Initialize log level on first use
  (when (not *current-log-level*)
    (let ((level-str (or (config-get '(logging level)) "INFO")))
      (set! *current-log-level* (or (assq-ref *log-levels* (string->symbol level-str)) 1))))
  (let ((level-num (assq-ref *log-levels* level)))
    (when (and level-num (>= level-num *current-log-level*))
      (let ((message (apply format #f format-str args)))
        (format #t "TEST LOG [~a]: ~a~%" level message)))))

;; Test the initialization
(log-message 'INFO "Testing configuration initialization")
(log-message 'DEBUG "This should not show")
(format #t "Configuration test complete~%")