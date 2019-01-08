(require 'ert)
(require 'julia-ast-mode)

;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Comparison-of-Numbers.html
(defun float-equal (x y)
  (let ((float-tol 1.0e-6))
    (or (= x y)
        (< (/ (abs (- x y))
              (max (abs x) (abs y)))
           float-tol))))


(ert-deftest test-julia-ast ()
  (should (equal
           (julia-ast-sexpr-from-julia "1 + 1")
           '(:call :+ 1 1)))
  (should (equal
           (julia-ast-sexpr-from-julia "a = 1")
           '(:assign :a 1)))
  (should (equal
           2
           (julia-ast-eval-sexpr '(:call :+ 1 1))))
  (should (equal
           1
           (julia-ast-eval-sexpr '(:assign :a 1))))
  (should (equal 2 (julia-ast-eval-sexpr
                    (julia-ast-sexpr-from-julia "1 + 1"))))
  (should (float-equal 8.0 (julia-ast-eval-sexpr
                            (julia-ast-sexpr-from-julia "sqrt(64.0)"))))
  (should (equal 1 (julia-ast-eval-sexpr
                    (julia-ast-sexpr-from-julia "a = 1"))))
  (julia-ast-eval-sexpr
   (julia-ast-sexpr-from-julia
    "function abc(x, y) x * y end"))
  (should (equal 42 (julia-ast-eval-sexpr
                     (julia-ast-sexpr-from-julia "abc(21, 2)"))))
  (should (equal "42" (julia-ast-eval-sexpr
                       (julia-ast-sexpr-from-julia "abc(\"4\", \"2\")")))))
