test: julisp-mode.el julisp-test.el Makefile
	LD_LIBRARY_PATH=`pwd`:$(EMACS_FFIDIR):$(JULIA_LIBDIR):$$LD_LIBRARY_PATH; \
	export LD_LIBRARY_PATH; \
	$(GDB) $(EMACS_BUILDDIR)/src/emacs -batch -L `pwd` -L $(EMACS_FFIDIR) -l ffi -l ert -l seq -l julisp-test.el \
	  -f ert-run-tests-batch-and-exit
