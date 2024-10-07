package http_server

import "core:bytes"
import "core:fmt"
import "core:log"
import "core:net"
import "core:os"
import "core:strconv"

ENDPOINT :: "127.0.0.1:80"

main :: proc() {
	context.logger = log.create_console_logger()

	if len(os.args) < 2 {
		fmt.printfln("Usage: %s <port>", os.args[0])

		os.exit(1)
	}

	port, port_ok := strconv.parse_u64_of_base(os.args[1], 10)
	if !port_ok {
		fmt.printfln("Invalid port number: %s", os.args[1])

		os.exit(1)
	}

	log.debugf("Starting server on port %d", port)

	assert(port <= 65535)
	endpoint, endpoint_parse_ok := net.parse_endpoint(ENDPOINT)
	if !endpoint_parse_ok {
		log.errorf("Failed to parse endpoint: %s\n", ENDPOINT)

		os.exit(1)
	}

	endpoint.port = int(port)

	listen_socket, listen_error := net.listen_tcp(endpoint)
	if listen_error != nil {
		log.errorf("Failed to listen on %v: %v", endpoint, listen_error)

		os.exit(1)
	}

	fmt.printfln("Listening on address %v, port %d", endpoint.address, endpoint.port)

	b: bytes.Buffer
	bytes.buffer_init_allocator(&b, 0, 2048)
	defer bytes.buffer_destroy(&b)

	// Create a default response
	bytes.buffer_write_string(&b, "HTTP/1.1 200 OK\r\n")
	bytes.buffer_write_string(&b, "Content-Type: text/html; charset=UTF-8\r\n")
	bytes.buffer_write_string(&b, "\r\n")
	bytes.buffer_write_string(&b, "<html><body>Hello from ODIN!</body></html>\r\n")
	welcome_message := bytes.buffer_to_bytes(&b)

	recv_buffer: [4096]byte

	for {
		client_socket, client_endpoint, accept_error := net.accept_tcp(listen_socket)
		if accept_error != nil {
			log.errorf("Failed to accept socket: %v", accept_error)

			continue
		}
		defer net.close(client_socket)

		log.infof("Accepted connection from %v", client_endpoint)

        has_double_newlines :: proc(data: []byte) -> bool {
            last_4 := data[len(data) - 4:]
            log.debugf(
                "last_4: %#02x, %#02x, %02x, %02x",
                last_4[0],
                last_4[1],
                last_4[2],
                last_4[3]
            )

            return bytes.compare(last_4, []byte{'\r', '\n', '\r', '\n'}) == 0
        }

        bytes_received := 255
        for bytes_received != 0 {
            n, recv_error := net.recv_tcp(client_socket, recv_buffer[:])
            if recv_error != nil {
                log.errorf("Failed to receive data: %v", recv_error)

                break
            }

            log.debugf("received n'''n%s\n'''", recv_buffer[:n])

            if has_double_newlines(recv_buffer[:n]) {
                break
            }

            bytes_received = n
        }

		// @TODO: Parse request

		bytes_written, send_err := net.send_tcp(client_socket, welcome_message)
		if send_err != nil {
			log.errorf("Failed to send welcome message: %s", welcome_message)
		}

	}
}
