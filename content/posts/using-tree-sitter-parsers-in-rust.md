---
title: "Using Tree-sitter Parsers in Rust"
date: 2019-08-07T11:20:33-07:00
tags:
- Software
- Rust
- Tree-sitter
---

*Update: 2022-12-26: Fixed unwrap() on Err by updating to latest tree-sitter*
*Update: 2019-08-10: Fixed rerun directive in `build.rs`*

[Tree-sitter] is a parser generator tool and parsing library.
It generates portable parsers that can be used in several languages including Rust.
Tree-sitter grammars are available for several languages.

This is a game changer because it lowers the barrier to entry for writing language tooling.
You no longer need to write your own parser.
With Tree-sitter, you can now simply use an existing parser.

[Tree-sitter]: https://tree-sitter.github.io/tree-sitter

## Toolchain

Tree-sitter grammars are written in Javascript.
The grammars are executed using Node to generate the grammar JSON.
The Tree-sitter CLI uses the grammar JSON to generate a C-based parser.
The parser is compiled into a Rust binary and used via the Rust Tree-sitter bindings.

## Install the Dependencies

Node is required to generate the grammar JSON.
Install node:

```sh
sudo apt-get install nodejs
```

NOTE: This article assumes you have Rust and a C compiler installed.

## Create a New Rust Project

```sh
cargo new tree-sitter-verilog-test
cd tree-sitter-verilog-test
git init
git add .
git commit -m "Initial commit"
```

## Obtain the Grammar

A list of existing Tree-sitter grammars is available at https://tree-sitter.github.io/tree-sitter.

I'll be using the Verilog grammar.
Obtain the grammar:

```sh
git submodule add https://github.com/tree-sitter/tree-sitter-verilog.git
git commit -m "Add tree-sitter-verilog"
```

## Generate the Parser

```sh
cd tree-sitter-verilog
npm install
```

This installs the Tree-sitter CLI and runs `tree-sitter generate` which executes the grammar Javascript to generate the grammar JSON then generates the C-based parser.
The parser is written to the `tree-sitter-verilog/src/` directory.

## Compile the Parser

A [Cargo build script] is needed to compile and link the parser into the Rust binary.

We need the [cc crate] for compiling C code into our Rust binary.
Add the `cc` crate to the `build-dependencies` section of `Cargo.toml`:

```toml
[build-dependencies]
cc = "1.0"
```

Create a `build.rs` build script with the contents:

```rust
fn main() {
    let language = "verilog";
    let package = format!("tree-sitter-{}", language);
    let source_directory = format!("{}/src", package);
    let source_file = format!("{}/parser.c", source_directory);

    println!("cargo:rerun-if-changed={}", source_file); // <1>

    cc::Build::new()
        .file(source_file)
        .include(source_directory)
        .compile(&package); // <2>
}
```

1. Tells Cargo to only re-run the build script if the parser source has changed.
2. Compiles the parser C code into the Rust binary.

NOTE: We could instead rerun on a change in the grammar Javascript and add a call to `npm install` to fully automate the building of the parser.

[Cargo build script]: https://doc.rust-lang.org/cargo/reference/build-scripts.html
[cc crate]: https://crates.io/crates/cc

## Use the Parser

We'll be using the parser via the Rust Tree-sitter bindings provided by the [tree-sitter crate].
Add the `tree-sitter` crate to the `dependencies` section of `Cargo.toml`:

```toml
[dependencies]
tree-sitter = "0.20.9"
```

Edit the contents of `src/main.rs` to be the following:

```rust
use tree_sitter::{Parser, Language};

extern "C" { fn tree_sitter_verilog() -> Language; }

fn main() {
    println!("Hello, world!");
}

#[test]
fn test_parser() {
    let language = unsafe { tree_sitter_verilog() };
    let mut parser = Parser::new();
    parser.set_language(language).unwrap();

    let source_code = "module mymodule(); endmodule";
    let tree = parser.parse(source_code, None).unwrap();

    assert_eq!(tree.root_node().to_sexp(), "(source_file (module_declaration (module_header (module_keyword) (module_identifier (simple_identifier))) (module_nonansi_header (list_of_ports))))");
}
```

Running `cargo test` should then give the following output:

```text
$ cargo test
   Compiling tree-sitter-verilog-test v0.1.0 (/home/rfdonnelly/repos/tree-sitter-verilog-test)
    Finished dev [unoptimized + debuginfo] target(s) in 6.27s
     Running target/debug/deps/tree_sitter_verilog_test-3a23b31b32f84a74

running 1 test
test test_parser ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

Finally commit the necessary files:

```sh
git add -f Cargo.lock Cargo.toml build.rs src/main.rs
git commit -m "Add Tree-sitter parser"
```

[tree-sitter crate]: https://crates.io/crates/tree-sitter
