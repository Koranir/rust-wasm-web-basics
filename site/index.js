import init, { log_msg } from "./hello_wasm.js";

async function run() {
    await init();

    log_msg();
}
run();
