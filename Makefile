ELISA_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
ELISA_RUNTIME ?= ../Elisa-compiler/build/runtime/elisacore_runtime.o
BUILD ?= build
# The sibling compiler checkout may contain unrelated uncommitted source edits.
# Keep the local debugger build usable by default; CI can set this to 0 for the
# strict product-freshness gate.
ELISA_ALLOW_STALE_STAGE1 ?= 1

.PHONY: check build server dap-server cli module-check ffi-check smoke managed-inspection-check managed-service-check protocol-events-check source-store-check request-whitespace-check cli-commands-check value-store-check historical-values-check query-engine-check advanced-analysis-check integration-contract-check trace-retention-check coordinator-seek-check capabilities-check trace-codec-check trace-recording-check trace-bundle-check clean

build: $(BUILD)/elisa-debugger

server: $(BUILD)/elisa-debugger-server

dap-server: $(BUILD)/elisa-debugger-dap-server

cli: $(BUILD)/elisa-debugger-cli

module-check: $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check
	"$(BUILD)/elisa-debugger-module-core-check"
	"$(BUILD)/elisa-debugger-module-data-check"
	"$(BUILD)/elisa-debugger-module-protocol-check"
	"$(BUILD)/elisa-debugger-module-trace-codec-check"
	"$(BUILD)/elisa-debugger-module-trace-recording-check"
	"$(BUILD)/elisa-debugger-module-trace-bundle-check"
	"$(BUILD)/elisa-debugger-edir-call-check"
	"$(BUILD)/elisa-debugger-session-check"
	"$(BUILD)/elisa-debugger-managed-inspection-check"
	"$(BUILD)/elisa-debugger-managed-service-check"
	"$(BUILD)/elisa-debugger-protocol-events-check"
	"$(BUILD)/elisa-debugger-source-store-check"
	"$(BUILD)/elisa-debugger-request-whitespace-check"
	"$(BUILD)/elisa-debugger-cli-commands-check"
	"$(BUILD)/elisa-debugger-value-store-check"
	"$(BUILD)/elisa-debugger-historical-values-check"
	"$(BUILD)/elisa-debugger-query-engine-check"
	"$(BUILD)/elisa-debugger-advanced-analysis-check"
	"$(BUILD)/elisa-debugger-integration-contract-check"
	"$(BUILD)/elisa-debugger-trace-retention-check"
	"$(BUILD)/elisa-debugger-coordinator-seek-check"
	"$(BUILD)/elisa-debugger-capabilities-check"

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

value-store-check: $(BUILD)/elisa-debugger-value-store-check
	"$(BUILD)/elisa-debugger-value-store-check"

historical-values-check: $(BUILD)/elisa-debugger-historical-values-check
	"$(BUILD)/elisa-debugger-historical-values-check"

query-engine-check: $(BUILD)/elisa-debugger-query-engine-check
	"$(BUILD)/elisa-debugger-query-engine-check"

advanced-analysis-check: $(BUILD)/elisa-debugger-advanced-analysis-check
	"$(BUILD)/elisa-debugger-advanced-analysis-check"

integration-contract-check: $(BUILD)/elisa-debugger-integration-contract-check
	"$(BUILD)/elisa-debugger-integration-contract-check"

trace-retention-check: $(BUILD)/elisa-debugger-trace-retention-check
	"$(BUILD)/elisa-debugger-trace-retention-check"

coordinator-seek-check: $(BUILD)/elisa-debugger-coordinator-seek-check
	"$(BUILD)/elisa-debugger-coordinator-seek-check"

capabilities-check: $(BUILD)/elisa-debugger-capabilities-check
	"$(BUILD)/elisa-debugger-capabilities-check"

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

$(BUILD)/elisa-debugger-module-trace-codec-check: tests/trace_codec_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-recording-check: tests/trace_recording_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-bundle-check: tests/trace_bundle_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-codec-check: $(BUILD)/elisa-debugger-module-trace-codec-check
	"$(BUILD)/elisa-debugger-module-trace-codec-check"

trace-recording-check: $(BUILD)/elisa-debugger-module-trace-recording-check
	"$(BUILD)/elisa-debugger-module-trace-recording-check"

trace-bundle-check: $(BUILD)/elisa-debugger-module-trace-bundle-check
	"$(BUILD)/elisa-debugger-module-trace-bundle-check"

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

$(BUILD)/elisa-debugger-value-store-check: tests/value_store_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-historical-values-check: tests/historical_values_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-query-engine-check: tests/query_engine_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-advanced-analysis-check: tests/advanced_analysis_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-integration-contract-check: tests/integration_contract_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-trace-retention-check: tests/trace_retention_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-coordinator-seek-check: tests/coordinator_seek_check.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-capabilities-check: tests/capabilities_check.elisa
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
	dap_initialize=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server"); dap_declared=$$(printf %s "$$dap_initialize" | sed -n 's/^Content-Length: //p' | tr -d '\r'); dap_body=$$(printf %s "$$dap_initialize" | sed -n '3p'); test "$$dap_declared" -eq "$$(printf %s "$$dap_body" | wc -c | tr -d ' ' )"
	printf 'Content-Length: 41\r\n\r\n{"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 48\r\n\r\n{"seq":1,"type":"request","command":"initialize"' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":1,"type":"request","command":"initialize"}x' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":01,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1 "type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request" "command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 58\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":"\\q"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 61\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":notjson}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 73\r\n\r\n{"seq":1,"type":"request","arguments":{"x":"\\"command\\":\\"initialize\\""}}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":1,"type":"request","command":"initialize",}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 56\r\n\r\n{"seq":1,"type":"request","command":"initialize",,"x":1}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 58\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":[{]}}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 49\r\n\r\n{"seq":4,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"stackFrames":[{"id":1,"name":"main","line":1'
	dap_timeline=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 43\r\n\r\n{"seq":4,"type":"request","command":"next"}Content-Length: 49\r\n\r\n{"seq":5,"type":"request","command":"stackTrace"}Content-Length: 47\r\n\r\n{"seq":6,"type":"request","command":"stepBack"}Content-Length: 49\r\n\r\n{"seq":7,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_timeline" | grep -F '"line":2'; echo "$$dap_timeline" | grep -F '"line":1'
	printf 'launch\npause\ncontinue\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'
	printf 'run\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=0'
	printf 'launch\r\npause\r\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=1'

clean:
	rm -rf $(BUILD)

# Included Elisa modules must invalidate executable and test products too.
$(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server $(BUILD)/elisa-debugger-cli $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check: $(shell find src -type f -name '*.elisa')
