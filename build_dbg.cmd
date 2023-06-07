cd source
cargo build --target wasm32-unknown-unknown
wasm-bindgen ./target/wasm32-unknown-unknown/debug/hello_wasm.wasm --target web --out-dir ../site