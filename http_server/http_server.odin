package http_server

import "core:net"
import "core:log"

main :: proc() {
    context.logger = log.create_console_logger()

    log.debugf("lol")
}