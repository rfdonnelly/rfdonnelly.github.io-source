---
title: "Using Tree Sitter Parsers in Rust"
date: 2019-08-07T11:20:33-07:00
draft: true
---

[Tree Sitter] is a parser generator tool and parsing library.
It generates portable parsers and provides bindings for several languages including Rust.
Tree Sitter grammars are available for several languages.

This is a game changer because it lowers the barrier to entry for writing language tooling.
You no longer need to write your own parser to implement language tooling.
With Tree Sitter, you can now simply use an existing parser.

[Tree Sitter]: https://tree-sitter.github.io/tree-sitter

## Installing the Tree Sitter CLI

The Tree Sitter CLI is required to generate a Tree Sitter parser from a Tree Sitter grammar.

Installing the Tree Sitter CLI is as simple as:

```sh
cargo install tree-sitter-cli
```


However, this doesn't work until the fix for [tree-sitter/tree-sitter#352] makes it into a release.
In the meantime, you'll need to clone and build the Tree Sitter repository.

The Tree Sitter repository uses Git Submodules so the `--recursive` flag must be used.

[tree-sitter/tree-sitter#352]: https://github.com/tree-sitter/tree-sitter/issues/352

```sh
git clone https://github.com/tree-sitter/tree-sitter.git --recursive
```

If you don't use the recursive flag, you'll get the following error on cargo build:

```text
cargo:warning=src\././utf16.h:10:22: fatal error: utf8proc.h: No such file or directory
```

Install dependencies

```sh
sudo apt-get install emscripten
```

Build WASM

```sh
./script/build-wasm
```

This didn't work for me so I removed the WASM dependency with the following patch.

```diff
diff --git a/cli/src/web_ui.rs b/cli/src/web_ui.rs
index 7ebced8..45a189a 100644
--- a/cli/src/web_ui.rs
+++ b/cli/src/web_ui.rs
@@ -11,9 +11,9 @@ const HTML: &'static str = include_str!("./web_ui.html");
 const PLAYGROUND_JS: &'static [u8] = include_bytes!("../../docs/assets/js/playground.js");

 #[cfg(unix)]
-const LIB_JS: &'static [u8] = include_bytes!("../../lib/binding_web/tree-sitter.js");
+const LIB_JS: &'static [u8] = &[];
 #[cfg(unix)]
-const LIB_WASM: &'static [u8] = include_bytes!("../../lib/binding_web/tree-sitter.wasm");
+const LIB_WASM: &'static [u8] = &[];

 #[cfg(windows)]
 const LIB_JS: &'static [u8] = &[];
```

Check the version:

```text
$ cargo run -- --version
    Finished dev [unoptimized + debuginfo] target(s) in 0.09s
     Running `target/debug/tree-sitter --version`
tree-sitter 0.15.7 (8657054e4b3d3ef50b0edcdf34b7bfcfc62edbe8)
```

Now that we have successfully built the Tree Sitter CLI we can install it for future convenience.

```sh
cd cli
cargo install --path .
```

## Create a New Rust Project

```sh
cargo new tree-sitter-verilog-test
cd tree-sitter-verilog-test
git init
git add .
git commit -m "Initial commit"
```

Add the following dependencies to `Cargo.toml`:

```toml
[dependencies]
tree-sitter = "0.3" # <1>

[build-dependencies]
cc = "1.0" # <2>
```

1. The Tree Sitter Rust bindings.
2. Library for compiling C code into a Rust binary.

A Cargo build script is needed to build and link the parser into our Rust binary.
Create a `build.rs` build script with the contents:

```rust
fn main() {
    let language = "verilog";
    let package = format!("tree-sitter-{}", language);
    let source_directory = format!("{}/src", package);
    let source_file = format!("{}/parser.c", source_directory);

    println!("rerun-if-changed={}", source_file); // <1>

    cc::Build::new()
        .file(source_file)
        .include(source_directory)
        .compile(&package); // <2>
}
```

1. Tells Cargo to only re-run the build script if the parser source has changed.
2. Compiles the parser C code into the Rust binary.

## Obtain the Grammar

A list of existing Tree Sitter grammars is available at https://tree-sitter.github.io/tree-sitter.

I'll be using the Verilog grammar.
Obtain the grammar and generate the parser as follows.

```sh
git clone https://github.com/tree-sitter/tree-sitter-verilog.git
cd tree-sitter-verilog
tree-sitter generate
```

This creates the `tree-sitter-verilog/src/` directory.

## Use the Grammar

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
git add -f Cargo.lock Cargo.toml build.rs src/main.rs tree-sitter-verilog/src/parser.c tree-sitter-verilog/src/tree_sitter/parser.h
git commit -m "Add Tree Sitter parser"
```
