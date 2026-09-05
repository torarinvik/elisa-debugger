ELISA_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
ELISA_RUNTIME ?= ../Elisa-compiler/build/runtime/elisacore_runtime.o
BUILD ?= build
# The sibling compiler checkout may contain unrelated uncommitted source edits.
# Keep the local debugger build usable by default; CI can set this to 0 for the
# strict product-freshness gate.
ELISA_ALLOW_STALE_STAGE1 ?= 1

.PHONY: check build server dap-server cli module-check ffi-check smoke managed-inspection-check clean

build: $(BUILD)/elisa-debugger

server: $(BUILD)/elisa-debugger-server

dap-server: $(BUILD)/elisa-debugger-dap-server

cli: $(BUILD)/elisa-debugger-cli

module-check: $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check
	"$(BUILD)/elisa-debugger-module-core-check"
	"$(BUILD)/elisa-debugger-module-data-check"
	"$(BUILD)/elisa-debugger-module-protocol-check"
	"$(BUILD)/elisa-debugger-module-trace-check"
	"$(BUILD)/elisa-debugger-edir-call-check"
	"$(BUILD)/elisa-debugger-session-check"
	"$(BUILD)/elisa-debugger-managed-inspection-check"

managed-inspection-check: $(BUILD)/elisa-debugger-managed-inspection-check
	"$(BUILD)/elisa-debugger-managed-inspection-check"

ffi-check: $(BUILD)/elisa-debugger-ffi-probe
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

$(BUILD)/elisa-debugger: $(shell find src -type f -name '*.elisa')
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" src/main.elisa

$(BUILD)/elisa-debugger-server: src/protocol/server.elisa src/protocol/framing.elisa src/protocol/request.elisa src/protocol/dispatcher.elisa src/core/errors.elisa src/core/identity.elisa src/core/capabilities.elisa src/core/cancellation.elisa src/core/session.elisa src/core/events.elisa src/engine/coordinator.elisa
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

check: $(BUILD)/elisa-debugger
	"$(BUILD)/elisa-debugger"

smoke: check server dap-server cli ffi-check
	printf '21 {"method":"discover"}\n' | "$(BUILD)/elisa-debugger-server" | grep -F '"protocolMajor":1'
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"supportsStepBack":true'
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 49\r\n\r\n{"seq":4,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"stackFrames":[{"id":1,"name":"main","line":1'
	printf 'launch\npause\ncontinue\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'

clean:
	rm -rf $(BUILD)
