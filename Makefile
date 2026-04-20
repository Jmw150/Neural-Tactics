COQ_MAKEFILE ?= coq_makefile
COQ_PROJECT := _CoqProject
COQ_GEN_MAKEFILE := Makefile.coq
LOCAL_OCAMLPATH := $(CURDIR)/_install/lib:$(OCAMLPATH)

export OCAMLPATH := $(LOCAL_OCAMLPATH)

.PHONY: all build dune-build coq-build clean test regen-coq

all: build

build: dune-build coq-build

dune-build:
	dune build @all
	dune install --prefix _install

coq-build: $(COQ_GEN_MAKEFILE)
	$(MAKE) -f $(COQ_GEN_MAKEFILE) all

test: build

regen-coq: $(COQ_GEN_MAKEFILE)

$(COQ_GEN_MAKEFILE): $(COQ_PROJECT)
	$(COQ_MAKEFILE) -f $(COQ_PROJECT) -o $(COQ_GEN_MAKEFILE)

clean:
	@if [ -f $(COQ_GEN_MAKEFILE) ]; then $(MAKE) -f $(COQ_GEN_MAKEFILE) clean; fi
	rm -f $(COQ_GEN_MAKEFILE) $(COQ_GEN_MAKEFILE).conf
	dune clean
