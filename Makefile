ELISA_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
ELISA_RUNTIME ?= ../Elisa-compiler/build/runtime/elisacore_runtime.o
BUILD ?= build
# The sibling compiler checkout may contain unrelated uncommitted source edits.
# Keep the local debugger build usable by default; CI can set this to 0 for the
# strict product-freshness gate.
ELISA_ALLOW_STALE_STAGE1 ?= 1

.PHONY: check build server dap-server cli module-check ffi-check smoke managed-inspection-check managed-service-check protocol-events-check source-store-check request-whitespace-check cli-commands-check clean

build: $(BUILD)/elisa-debugger

server: $(BUILD)/elisa-debugger-server

dap-server: $(BUILD)/elisa-debugger-dap-server

cli: $(BUILD)/elisa-debugger-cli

module-check: $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-cli-commands-check
	"$(BUILD)/elisa-debugger-module-core-check"
	"$(BUILD)/elisa-debugger-module-data-check"
	"$(BUILD)/elisa-debugger-module-protocol-check"
	"$(BUILD)/elisa-debugger-module-trace-check"
	"$(BUILD)/elisa-debugger-edir-call-check"
	"$(BUILD)/elisa-debugger-session-check"
	"$(BUILD)/elisa-debugger-managed-inspection-check"
	"$(BUILD)/elisa-debugger-managed-service-check"
	"$(BUILD)/elisa-debugger-protocol-events-check"
	"$(BUILD)/elisa-debugger-source-store-check"
	"$(BUILD)/elisa-debugger-request-whitespace-check"
	"$(BUILD)/elisa-debugger-cli-commands-check"

managed-inspection-check: $(BUILD)/elisa-debugger-managed-inspection-check
	"$(BUILD)/elisa-debugger-managed-inspection-check"

managed-service-check: $(BUILD)/elisa-debugger-managed-service-check
	"$(BUILD)/elisa-debugger-managed-service-check"

protocol-events-check: $(BUILD)/elisa-debugger-protocol-events-check
	"$(BUILD)/elisa-debugger-protocol-events-check"

source-store-check: $(BUILD)/elisa-debugger-source-store-check
	"$(BUILD)/elisa-debugger-source-store-check"

request-whitespace-check: $(BUILD)/elisa-debugger-request-whitespace-check
	"$(BUILD)/elisa-debugger-request-whitespace-check"

cli-commands-check: $(BUILD)/elisa-debugger-cli-commands-check
	"$(BUILD)/elisa-debugger-cli-commands-check"

ffi-check: $(BUILD)/elisa-debugger-ffi-probe
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

$(BUILD)/elisa-debugger: $(shell find src -type f -name '*.elisa')
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" src/main.elisa

$(BUILD)/elisa-debugger-server: src/protocol/server.elisa src/protocol/framing.elisa src/protocol/request.elisa src/protocol/dispatcher.elisa src/protocol/managed_service.elisa src/core/errors.elisa src/core/identity.elisa src/core/capabilities.elisa src/core/cancellation.elisa src/core/session.elisa src/core/events.elisa src/engine/coordinator.elisa src/engine/managed.elisa src/engine/default_image.elisa src/replay/engine.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-dap-server: src/protocol/dap_server.elisa src/protocol/dispatcher.elisa src/core/cancellation.elisa src/engine/coordinator.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-cli: src/cli/entrypoint.elisa src/protocol/dispatcher.elisa src/core/cancellation.elisa src/engine/coordinator.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-core-check: tests/module_core_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-data-check: tests/module_data_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-protocol-check: tests/module_protocol_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-check: tests/module_trace_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-edir-call-check: tests/edir_call_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-session-check: tests/session_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-ffi-probe: tests/ffi_probe.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-inspection-check: tests/managed_inspection_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-service-check: tests/managed_service_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-protocol-events-check: tests/protocol_events_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-source-store-check: tests/source_store_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-request-whitespace-check: tests/request_whitespace_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-cli-commands-check: tests/cli_commands_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

check: $(BUILD)/elisa-debugger
	"$(BUILD)/elisa-debugger"

smoke: check server dap-server cli ffi-check
	printf '655360 ' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf '21 {' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 655360\r\n\r\n' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf '21 {"method":"discover"}\n' | "$(BUILD)/elisa-debugger-server" | grep -F '"protocolMajor":1'
	server_timeline=$$(printf '30 {"method":"initialize","id":1}\n26 {"method":"launch","id":2}\n25 {"method":"pause","id":3}\n24 {"method":"step","id":4}\n31 {"method":"reverseStep","id":5}\n25 {"method":"close","id":6}\n' | "$(BUILD)/elisa-debugger-server"); echo "$$server_timeline" | grep -F '"id":"4","ok":true'; echo "$$server_timeline" | grep -F '"id":"5","ok":true'; printf '%s\n' "$$server_timeline" | while IFS=' ' read -r declared payload; do test "$$declared" -eq "$$(printf %s "$$payload" | wc -c | tr -d ' ')"; done
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"supportsStepBack":true'
	dap_initialize=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server"); dap_declared=$$(printf %s "$$dap_initialize" | sed -n 's/^Content-Length: //p'); dap_body=$$(printf %s "$$dap_initialize" | sed -n '3p'); test "$$dap_declared" -eq "$$(printf %s "$$dap_body" | wc -c | tr -d ' ' )"
	printf 'Content-Length: 41\r\n\r\n{"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 48\r\n\r\n{"seq":1,"type":"request","command":"initialize"' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 49\r\n\r\n{"seq":4,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"stackFrames":[{"id":1,"name":"main","line":1'
	dap_timeline=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 43\r\n\r\n{"seq":4,"type":"request","command":"next"}Content-Length: 49\r\n\r\n{"seq":5,"type":"request","command":"stackTrace"}Content-Length: 47\r\n\r\n{"seq":6,"type":"request","command":"stepBack"}Content-Length: 49\r\n\r\n{"seq":7,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_timeline" | grep -F '"line":2'; echo "$$dap_timeline" | grep -F '"line":1'
	printf 'launch\npause\ncontinue\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'

clean:
	rm -rf $(BUILD)

# Included Elisa modules must invalidate executable and test products too.
$(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server $(BUILD)/elisa-debugger-cli $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-cli-commands-check: $(shell find src -type f -name '*.elisa')
