.PHONY: all build clean test

COQFLAGS=-R theories RocqOwlTactics
LOCAL_OCAMLPATH=$(CURDIR)/_install/lib:$(OCAMLPATH)

all: build

build:
	dune build
	dune install --prefix _install

clean:
	dune clean

test:
	dune build @all
	dune install --prefix _install
	OCAMLPATH="$(LOCAL_OCAMLPATH)" coqc $(COQFLAGS) theories/OwlTactics.v
	OCAMLPATH="$(LOCAL_OCAMLPATH)" coqc $(COQFLAGS) -R examples RocqOwlTacticsExamples examples/demo.v
