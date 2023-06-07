# Web Development with WASM
## Part 1 – What is WASM and why should we use it?
WebAssembly (WASM) is a new, portable, binary format, built to be used where high-performance is needed on the web.

WASM is very low-level, intended to be a compilation target instead of directly edited and fills in the gaps of JavaScript. Where JS is high-level but slow, WASM allows for much better control of the hardware. As WASM is a binary compiled from other languages, it inherits all the advantages and disadvantages of the language you use to create it.

With a borrow checker and static analysis baked into the compiler, Rust offers an almost completely memory-safe experience that can catch most bugs before you even run the program. For those experienced in JS, it is quite a welcome change.

With both low-level control, blazing-fast performance, and high-level convenience, Rust is an ideal language for high-intensity web computing, with a host of community-made tools and an ever-growing ecosystem that can take advantage of whatever the web has to offer.

## Part 2 – Rust to WASM
Before you compile Rust to WASM, you will need two tools in addition to the base Rust tools (i.e. `rustup`, `cargo`, etc.) - the `wasm-bindgen` CLI, and the `wasm32-unknown-unknown` compile target.

### `wasm32-unknown-unknown`
To compile a binary from rust, you need a build target that corresponds to the system that you want to build to. For example, to compile to `x86_64 Windows`, you need the `x86_64-pc-windows-msvc` build target. This comes installed with a Windows Rust install, but more can be installed at any time with the `rustup target add` command.

To compile to WASM, you need the `wasm32-unknown-unknown` build target, easily installed by running `rustup target add wasm32-unknown-unknown`.

When running `cargo build` with the `--target wasm32-unknown-unknown` argument, a `.wasm` file will be output at the `./target/wasm32-unknown-unknown/<debug|release>/<project-name>.wasm`.

Unfortunately, that `.wasm` file is useless without proper interfacing to JS and web properties.

### `wasm-bindgen`
Fortunately for us, the Rust community already has an easy and effective tool for rust-web interfacing: `wasm-bindgen`. 

`wasm-bindgen` is a crate and CLI that allows you to, in conjunction with the `web-sys` and `js-sys` crates, create JS bindings for Rust WASM.

To install the `wasm-bindgen` CLI, run `cargo install wasm-bindgen-cli`. The `wasm-bindgen` CLI is what produces the `.wasm` and `.js` files required to use your Rust code from JS. It takes the `.wasm` file built by cargo and some arguments.

Running `wasm-bindgen` now won’t do anything, however. We need to declare the functions and structs we want to export out from inside our Rust code with the `wasm_bindgen` proc macro.

### `wasm_bindgen` Proc Macro
The `wasm_bindgen` proc macro serves as an access point for the `wasm-bindgen` CLI to ‘bind’ to, as well as ensuring that the types you use inside exported structs & functions are compatible with JS. You use it just as with `#[derive]` macros, placing it before `struct` and `impl` blocks.

> Note that both `pub struct`s and `struct`s get exported, but only `pub fn`s in impl blocks get exported.

## Part 3 – Using WASM in JS

We can import the files we created in the above step to our main JS file to use the functions and classes we exported by using the `import … from ‘…’` statement.

It is VERY IMPORTANT that when you want to import wasm bindings from our generated `.js` file that you import `init` first, then the rest of what you need, i.e:
``` js
import init, { my_func } from "./project name.js";
```

From there you should maek a function in the style:
``` js
async function run() {
	await init();

	// Whatever code you wanted to do
}
run()
```
`init()` must be called before any wasm classes/functions are used.

## Part 4 – “Hello, WASM”
This is tutorial on how to run console.log() in WASM from inside JS.

### Setup
The directory:
```
hello-wasm
| site
| source
```
We will have the `site` and `source` directories in our main directory. `site` will contain the data for our website and source will contain the Rust code.

Go ahead and initialize the source directory for rust by running `cargo init --lib` within it. Make sure you dont initialize Cargo in the main directory by accident!

We are going to use the `wasm-bindgen`, `web-sys`, and `js-sys` crates for this project, so go ahead and `cargo add` those.

We'll need the `console` feature from `web-sys`, which handles accessing the JS console from WASM.

Your `Cargo.toml` should look something like this:

```toml
[package]
name = "hello-wasm"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
js-sys = "0.3.63"
wasm-bindgen = "0.2.86"

[dependencies.web-sys]
version = "0.3.63"
features = [
    "console"
]
```

Lets open up `lib.rs` and delete whatever was inside, then make a new public function called `log_msg`:
``` rs
pub fn log_msg() {
}
```
We'll use `web-sys`'s `console::log_1()` funtion to produce an output to the JS terminal. As Rust does not support variable-length functions, `web-sys`'s logging function has a variant for each input length.
``` rs
pub fn log_msg() {
    web_sys::console::log_1("Hello, WASM!")
}
```
You'll notice that there is an error! The logging function needs a `&JsValue`, but we gave it a `&'static str`. Fortunately, `JsValue` provides a `From<&str>` implementation, so we just need to add a `&` and an `.into()`.
``` rs
pub fn log_msg() {
    web_sys::console::log_1(&"Hello, WASM!".into())
}
```
Now lets add JS bindings. Add the `#[wasm_bindgen]` proc macro, as well as importing everything in `wasm_bindgen::prelude`.
``` rs
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn log_msg() {
    web_sys::console::log_1(&"Hello, WASM!".into())
}

```
At this point we have what we need to compile. 

Run `cargo build --target wasm32-unknown-unknown` and see your `.wasm` appear in `./target/wasm32-unknown-unknown/debug`.

Whoops, no binary! You have to add this after the `[package]` block in `Cargo.toml`:
``` toml
[lib]
crate-type = ["cdylib"]
```
This will make cargo compile to a binary. Don't worry, `cdylib` doesn't have anything to do with C.

Now that we have our `.wasm` we can use `wasm-bindgen` to create JS bindings.

Here's the arguments that we'll use: `wasm-bindgen ./target/wasm32-unknown-unknown/debug/hello_wasm.wasm --target web --out-dir ../site`

Lets step through the arguments.
1. `wasm-bindgen` is the executable name
2. `./target/wasm32-unknown-unknown/debug/hello_wasm.wasm` is the path to our `.wasm` binary
3. `--target web` tells `wasm-bindgen` to not use any external dependancies so we can just add the output to our site
4. `--out-dir` tells `wasm-bindgen` where to place our files. We chose to go to `../site`, which is the `site` directory in the parent directory of `source`, `web-basics-wasm`.

That's a lot of arguments! Lets make a quick build script so we don't have to type that out every time.

Create a file called `build_dbg.cmd` or whatever shell script your system uses in the the `web-basics-wasm` root directory. In it, add:
``` cmd
cd source
cargo build --target wasm32-unknown-unknown
wasm-bindgen ./target/wasm32-unknown-unknown/debug/hello_wasm.wasm --target web --out-dir ../site
```

We can run that whenever we want to build or project.

If we navigate to `hello-wasm/site`, we'll see that there are four new files: `hello_wasm_bg.wasm`, `hello_wasm_bg.wasm.d.ts`, `hello_wasm.d.ts` and `hello_wasm.js`.

Add `index.html` and `index.js` to the pile.

We won't do anything too special with index.html.

index.html:
``` html
<!DOCTYPE html>
<body>
    <h1>Hello WASM!</h1>
    <script type="module" src="index.js"></script>
</body>
```
And in index.js we'll import the genrated js:
``` js
import init, { log_msg } from "./hello_wasm.js";

async function run() {
    await init();

    log_msg();
}
run();
```

That's it! Run that site through whatever method, and it should just produce "Hello, WASM!" in the console.

With that setup done, go check out the [`wasm-bindgen` Documentation](https://rustwasm.github.io/wasm-bindgen/) for more advanced things!