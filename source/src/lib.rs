use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn log_msg() {
    web_sys::console::log_1(&"Hello, WASM!".into())
}
