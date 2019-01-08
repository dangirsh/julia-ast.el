(require 'libjulia)

;;; Exprs and Sexprs

(defun julia-ast-elisp-head-to-julia (head)
  (pcase head
    (:assign (jl-symbol (ffi-make-c-string "=")))
    (_ (libjulia-julia-from-elisp head))))

(defun julia-ast-line-annotationp (sexpr)
  (when (listp sexpr)
    (equal (car sexpr) :line_annotation)))

(defun julia-ast-sexp-transform (p f sexp)
  "For any sub s-expression in sexp chosen by predicate p,
replace it with f applied to that sexp. If f returns nil, remove
that sub s-expression."
  (if (listp sexpr)
      (pcase sexpr
        ((pred p) (funcall f sexpr))
        (_ `(,(car sexpr) ,(mapcar #'(lambda (sub-sexpr) (julia-ast-sexp-transform p f sub-sexpr)) (cdr sexpr)))))
    sexp))

(defun julia-ast--clean-sexpr (sexpr)
  (julia-ast-sexp-transform
   #'(lambda (s) (equal (car s) :line_annotation))
   #'(lambda (_) nil)
   sexpr))

(defun julia-ast-expr-from-sexpr (sexpr)
  (if (listp sexpr)
      (when-let* ((clean-sexpr (julia-ast--clean-sexpr sexpr))
                  (head (julia-ast-elisp-head-to-julia (car clean-sexpr)))
                  (tail (mapcar #'julia-ast-expr-from-sexpr (seq-remove #'identity (cdr clean-sexpr)))))
        ;; recursively build an Expr object
        (libjulia-jl-call "Expr" `(,head ,@tail)))
    ;; atoms are their own exprs
    (libjulia-julia-from-elisp sexpr)))


(defun julia-ast-eval-expr (julia-expr-ptr &optional julia-module-name)
  (libjulia-elisp-from-julia
   (jl-toplevel-eval
    (libjulia-get-module julia-module-name)
    julia-expr-ptr)))

(defun julia-ast-eval-sexpr (sexpr &optional julia-module-name)
  (julia-ast-eval-expr (julia-ast-expr-from-sexpr sexpr) julia-module-name))

(defun julia-ast-sexpr-from-julia (julia-src-str)
  (read (libjulia-jl-call "clean_sexpr" `(,julia-src-str) "Julisp")))

;; (defun julia-ast-edebug-eval-defun (fn edebug-it)
;;   (let ((eval julia-ast-eval-sexpr)
;;         (funcall fn edebug-it))))

;; (advice-add 'edebug-eval-defun :around #'libjulia-edebug-eval-defun)

(defun julia-ast-load ()
  (let* ((this-dir
          (if (locate-library "julia-ast-mode")
              (file-name-directory (locate-library "julia-ast-mode"))
            default-directory))
         (module-dir (concat this-dir "Julisp")))
    (message "Loading Julisp Julia package from %s." module-dir)
    (libjulia-eval-str (format
                        "cd(\"%s\"); using Pkg; Pkg.activate(\".\"); using Julisp"
                        module-dir)))
  ;; (async-start
  ;;  ;; What to do in the child process
  ;;  (lambda ()
  ;;    (libjulia-eval-str (format
  ;;                        "cd(\"%s\"); using Pkg; Pkg.activate(\".\"); using Julisp"
  ;;                        (concat default-directory "Julisp"))))
  ;;  ;; What to do when it finishes
  ;;  (lambda (result)
  ;;    (message "Finished loading support Julia code for libjulia. Result: %s" result)))
  )

(julia-ast-load)

(define-derived-mode julia-ast-mode emacs-lisp-mode "Julisp"
  "Major mode for editing julia code as sexprs.")

(defun lispy--eval-julia-ast (str)
  (libjulia-eval-sexpr (read str)))

(provide 'julia-ast-mode)
