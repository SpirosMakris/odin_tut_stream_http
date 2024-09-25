package http_server

import "core:net"
import "core:log"
import "core:os"
import "core:fmt"
import "core:strconv"

main :: proc() {
    context.logger = log.create_console_logger()

    if len(os.args) < 2 {
        fmt.printfln("Usage: %s <port>", os.args[0])

        os.exit(1)
    }

    port, port_ok := strconv.parse_u64_of_base(os.args[1], 10)
    if !port_ok {
        fmt.printfln("Invalid port number: %s", os.args[1])
    }

    log.debugf("Starting server on port %d", port)
}