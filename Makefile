ELISA_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
# The compiler is commonly located under a workspace path containing spaces.
# Keep it as one shell argument in every recipe, including command-line
# overrides such as `make ELISA_COMPILER=/path/with\ spaces/elisac-stage1`.
override ELISA_COMPILER := "$(ELISA_COMPILER)"
ELISA_RUNTIME ?= $(abspath ../Elisa-compiler/build/runtime/elisacore_runtime.o)
# Large aggregate fixtures exercise the modules in one executable entry point. Keep their
# generated stack frames above macOS's default 8 MiB thread stack while leaving other hosts'
# linker defaults untouched.
ifeq ($(shell uname -s),Darwin)
ELISA_LINK_FLAGS ?= -Wl,-stack_size,0x2000000
else
ELISA_LINK_FLAGS ?=
endif
# Keep both spellings while older stage1 binaries are still in circulation. The wrapper's
# public name is ELISA_RUNTIME_OBJ; ELISA_STAGE1_RUNTIME_OBJ is the legacy name understood by
# pre-wrapper product binaries. Supplying both makes this Makefile independent of that rollout.
ELISA_RUNTIME_ENV = ELISA_RUNTIME_OBJ="$(ELISA_RUNTIME)" ELISA_STAGE1_RUNTIME_OBJ="$(ELISA_RUNTIME)" ELISA_STAGE1_LINK="$(ELISA_LINK_FLAGS)"
BUILD ?= build
ELISA_EDIR_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
ELISA_EDIR_ALLOW_STALE_STAGE1 ?= 0
COMPILER_EDIR_FIXTURE := tests/compiler_edir_arithmetic_fixture.elisa
COMPILER_EDIR_ARTIFACT := $(BUILD)/compiler_edir_arithmetic.edir
COMPILER_NATIVE_ARTIFACT := $(BUILD)/compiler_edir_arithmetic_native
COMPILER_EDIR_INTEGRATION_CHECK := $(BUILD)/elisa-debugger-compiler-edir-integration-check
COMPILER_EDIR_EXPECTED_EXIT := 42
COMPILER_EDIR_DAP_LOCAL_REFERENCE := 5
PROCESS_SPAWN_CHECK_PARENT_MODE := --process-check-parent
PROCESS_SPAWN_CHECK_RESERVED_FIRST := reserved-first
PROCESS_SPAWN_CHECK_RESERVED_SECOND := reserved-second
IDLESS_LAUNCH_PAYLOAD_LENGTH := 19
DAP_ZERO_SEQUENCE_LAUNCH_PAYLOAD_LENGTH := 45
SERVER_TEST_PAGE_SIZE := 1
SERVER_TEST_STALE_GENERATION := 1
SERVER_TEST_CURRENT_GENERATION := 2
SERVER_TEST_FIRST_STEP_INSTRUCTION := 1
SERVER_TEST_FIRST_STEP_ACCUMULATOR := 17
EDIR_FILE_TOO_LARGE_BYTES := 24926
EDIR_FILE_TRUNCATED_BYTES := 5
EDIR_FILE_CORRUPT_PREFIX_BYTES := 1
DAP_UNKNOWN_SOURCE_LINE := 0
DAP_EXPECTED_MAPPED_COLUMN := 4
DAP_ZERO_BASED_MAPPED_LINE := 40
DAP_ZERO_BASED_MAPPED_COLUMN := 3
# The sibling compiler checkout may contain unrelated uncommitted source edits.
# Keep the local debugger build usable by default; CI can set this to 0 for the
# strict product-freshness gate.
ELISA_ALLOW_STALE_STAGE1 ?= 1
# Elisa's stage1 compiler does not emit make dependency files for `include`d
# modules.  Keep focused checks dependent on every source module so a changed
# include cannot leave a silently stale executable behind.
ELISA_SOURCE_FILES := $(shell find src -type f -name '*.elisa')

.PHONY: cli-flush-check

build: $(BUILD)/elisa-debugger

server: $(BUILD)/elisa-debugger-server

dap-server: $(BUILD)/elisa-debugger-dap-server

cli: $(BUILD)/elisa-debugger-cli

cli-flush-check: $(BUILD)/elisa-debugger-cli
	sh tests/cli_flush_check.sh "$(BUILD)/elisa-debugger-cli"

module-check: $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-edir-codec-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-managed-trace-service-check $(BUILD)/elisa-debugger-managed-memory-write-history-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-protocol-encoding-check $(BUILD)/elisa-debugger-protocol-framing-check $(BUILD)/elisa-debugger-remote-authentication-check $(BUILD)/elisa-debugger-trace-storage-decode-check $(BUILD)/elisa-debugger-trace-reader-encoded-check $(BUILD)/elisa-debugger-checkpoint-state-check $(BUILD)/elisa-debugger-trace-manifest-status-check $(BUILD)/elisa-debugger-adapter-recording-bounds-check $(BUILD)/elisa-debugger-runtime-status-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-request-operands-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-query-evaluator-check $(BUILD)/elisa-debugger-breakpoint-manager-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-integration-surface-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check $(BUILD)/elisa-debugger-dap-payload-check $(BUILD)/elisa-debugger-ffi-probe $(BUILD)/elisa-debugger-path-policy-check $(BUILD)/elisa-debugger-process-spawn-check

# Keep the remote artifact transfer regression in the aggregate module gate.
module-check: $(BUILD)/elisa-debugger-remote-artifacts-check
module-check: $(BUILD)/elisa-debugger-native-elf-check
module-check: $(BUILD)/elisa-debugger-native-macho-check
module-check: $(BUILD)/elisa-debugger-native-artifact-check
module-check: $(BUILD)/elisa-debugger-native-symbols-identity-check
module-check: $(BUILD)/elisa-debugger-native-symbol-loader-check
module-check: $(BUILD)/elisa-debugger-replay-branches-check
module-check: $(BUILD)/elisa-debugger-replay-provenance-check
module-check: $(BUILD)/elisa-debugger-state-integrity-check
module-check: $(BUILD)/elisa-debugger-trace-checkpoint-validation-check
module-check: $(BUILD)/elisa-debugger-full-checkpoint-codec-check
module-check: $(BUILD)/elisa-debugger-managed-memory-write-history-check
module-check: $(BUILD)/elisa-debugger-dap-events-check
module-check: edir-file-loader-check

	"$(BUILD)/elisa-debugger-module-core-check"
	"$(BUILD)/elisa-debugger-module-data-check"
	"$(BUILD)/elisa-debugger-module-protocol-check"
	"$(BUILD)/elisa-debugger-module-trace-codec-check"
	"$(BUILD)/elisa-debugger-module-trace-recording-check"
	"$(BUILD)/elisa-debugger-module-trace-bundle-check"
	"$(BUILD)/elisa-debugger-edir-call-check"
	"$(BUILD)/elisa-debugger-edir-codec-check"
	"$(BUILD)/elisa-debugger-session-check"
	"$(BUILD)/elisa-debugger-managed-inspection-check"
	"$(BUILD)/elisa-debugger-managed-service-check"
	"$(BUILD)/elisa-debugger-managed-trace-service-check"
	"$(BUILD)/elisa-debugger-managed-memory-write-history-check"
	"$(BUILD)/elisa-debugger-protocol-events-check"
	"$(BUILD)/elisa-debugger-protocol-encoding-check"
	"$(BUILD)/elisa-debugger-protocol-framing-check"
	"$(BUILD)/elisa-debugger-trace-storage-decode-check"
	"$(BUILD)/elisa-debugger-trace-reader-encoded-check"
	"$(BUILD)/elisa-debugger-trace-checkpoint-validation-check"
	"$(BUILD)/elisa-debugger-remote-authentication-check"
	"$(BUILD)/elisa-debugger-remote-artifacts-check"
	"$(BUILD)/elisa-debugger-native-elf-check"
	"$(BUILD)/elisa-debugger-native-macho-check"
	"$(BUILD)/elisa-debugger-native-artifact-check"
	"$(BUILD)/elisa-debugger-native-symbols-identity-check"
	"$(BUILD)/elisa-debugger-native-symbol-loader-check"
	"$(BUILD)/elisa-debugger-checkpoint-state-check"
	"$(BUILD)/elisa-debugger-full-checkpoint-codec-check"
	"$(BUILD)/elisa-debugger-dap-events-check"
	"$(BUILD)/elisa-debugger-replay-provenance-check"
	"$(BUILD)/elisa-debugger-replay-branches-check"
	"$(BUILD)/elisa-debugger-state-integrity-check"
	"$(BUILD)/elisa-debugger-trace-manifest-status-check"
	"$(BUILD)/elisa-debugger-adapter-recording-bounds-check"
	"$(BUILD)/elisa-debugger-runtime-status-check"
	"$(BUILD)/elisa-debugger-source-store-check"
	"$(BUILD)/elisa-debugger-request-whitespace-check"
	"$(BUILD)/elisa-debugger-request-operands-check"
	"$(BUILD)/elisa-debugger-cli-commands-check"
	"$(BUILD)/elisa-debugger-value-store-check"
	"$(BUILD)/elisa-debugger-historical-values-check"
	"$(BUILD)/elisa-debugger-query-engine-check"
	"$(BUILD)/elisa-debugger-query-evaluator-check"
	"$(BUILD)/elisa-debugger-breakpoint-manager-check"
	"$(BUILD)/elisa-debugger-advanced-analysis-check"
	"$(BUILD)/elisa-debugger-integration-contract-check"
	"$(BUILD)/elisa-debugger-integration-surface-check"
	"$(BUILD)/elisa-debugger-trace-retention-check"
	"$(BUILD)/elisa-debugger-coordinator-seek-check"
	"$(BUILD)/elisa-debugger-capabilities-check"
	"$(BUILD)/elisa-debugger-dap-payload-check"
	"$(BUILD)/elisa-debugger-path-policy-check"
	"$(BUILD)/elisa-debugger-process-spawn-check" $(PROCESS_SPAWN_CHECK_PARENT_MODE) $(PROCESS_SPAWN_CHECK_RESERVED_FIRST) $(PROCESS_SPAWN_CHECK_RESERVED_SECOND)
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

managed-inspection-check: $(BUILD)/elisa-debugger-managed-inspection-check
	"$(BUILD)/elisa-debugger-managed-inspection-check"

managed-service-check: $(BUILD)/elisa-debugger-managed-service-check
	"$(BUILD)/elisa-debugger-managed-service-check"

managed-trace-service-check: $(BUILD)/elisa-debugger-managed-trace-service-check
	"$(BUILD)/elisa-debugger-managed-trace-service-check"

managed-source-path-check: $(BUILD)/elisa-debugger-managed-source-path-check
	"$(BUILD)/elisa-debugger-managed-source-path-check"

$(BUILD)/elisa-debugger-managed-source-path-check: tests/managed_source_path_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-terminal-checkpoint-check: tests/terminal_checkpoint_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

terminal-checkpoint-check: $(BUILD)/elisa-debugger-terminal-checkpoint-check
	"$(BUILD)/elisa-debugger-terminal-checkpoint-check"

protocol-events-check: $(BUILD)/elisa-debugger-protocol-events-check
	"$(BUILD)/elisa-debugger-protocol-events-check"

source-store-check: $(BUILD)/elisa-debugger-source-store-check
	"$(BUILD)/elisa-debugger-source-store-check"

$(BUILD)/elisa-debugger-replay-branches-check: tests/replay_branches_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

replay-branches-check: $(BUILD)/elisa-debugger-replay-branches-check
	"$(BUILD)/elisa-debugger-replay-branches-check"

$(BUILD)/elisa-debugger-replay-provenance-check: tests/replay_provenance_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

replay-provenance-check: $(BUILD)/elisa-debugger-replay-provenance-check
	"$(BUILD)/elisa-debugger-replay-provenance-check"

$(BUILD)/elisa-debugger-state-integrity-check: tests/state_integrity_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

state-integrity-check: $(BUILD)/elisa-debugger-state-integrity-check
	"$(BUILD)/elisa-debugger-state-integrity-check"

request-whitespace-check: $(BUILD)/elisa-debugger-request-whitespace-check
	"$(BUILD)/elisa-debugger-request-whitespace-check"

$(BUILD)/elisa-debugger-request-operands-check: tests/request_operands_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

request-operands-check: $(BUILD)/elisa-debugger-request-operands-check
	"$(BUILD)/elisa-debugger-request-operands-check"

cli-commands-check: $(BUILD)/elisa-debugger-cli-commands-check
	"$(BUILD)/elisa-debugger-cli-commands-check"

value-store-check: $(BUILD)/elisa-debugger-value-store-check
	"$(BUILD)/elisa-debugger-value-store-check"

historical-values-check: $(BUILD)/elisa-debugger-historical-values-check
	"$(BUILD)/elisa-debugger-historical-values-check"

query-engine-check: $(BUILD)/elisa-debugger-query-engine-check
	"$(BUILD)/elisa-debugger-query-engine-check"

query-evaluator-check: $(BUILD)/elisa-debugger-query-evaluator-check
	"$(BUILD)/elisa-debugger-query-evaluator-check"

breakpoint-manager-check: $(BUILD)/elisa-debugger-breakpoint-manager-check
	"$(BUILD)/elisa-debugger-breakpoint-manager-check"

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

$(BUILD)/elisa-debugger-dap-payload-check: tests/dap_payload_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-dap-events-check: tests/dap_events_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-events-check: $(BUILD)/elisa-debugger-dap-events-check
	"$(BUILD)/elisa-debugger-dap-events-check"

dap-command-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	sh tests/dap_command_collision_check.sh "$(BUILD)/elisa-debugger-dap-server" "$(BUILD)/edir-fixture.edir"

dap-frame-length-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	sh tests/dap_frame_lengths_check.sh "$(BUILD)/elisa-debugger-dap-server"

# Exercise the real DAP transport first at the root frame and then inside the
# EDIR fixture's call, where stackTrace must not mislabel the callee as main.
dap-stack-frame-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	dap_stack_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stackTrace"}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"stepIn"}' '{"seq":9,"type":"request","command":"stepIn"}' '{"seq":10,"type":"request","command":"stackTrace"}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_stack_output=$$(printf %s "$$dap_stack_input" | "$(BUILD)/elisa-debugger-dap-server"); test "$$(printf %s "$$dap_stack_output" | grep -o '\"name\":\"main\"' | wc -l | tr -d ' ')" -eq 1; test "$$(printf %s "$$dap_stack_output" | grep -o '\"name\":\"frame\"' | wc -l | tr -d ' ')" -eq 1

dap-payload-check: $(BUILD)/elisa-debugger-dap-payload-check
	"$(BUILD)/elisa-debugger-dap-payload-check"

$(BUILD)/elisa-debugger-edir-fixture-writer: tests/edir_fixture_writer.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-edir-file-loader-check: tests/edir_file_loader_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

edir-file-loader-check: $(BUILD)/elisa-debugger-edir-fixture-writer $(BUILD)/elisa-debugger-edir-file-loader-check
	"$(BUILD)/elisa-debugger-edir-fixture-writer" > "$(BUILD)/edir-fixture.edir"
	: > "$(BUILD)/edir-empty.edir"
	head -c $(EDIR_FILE_TRUNCATED_BYTES) "$(BUILD)/edir-fixture.edir" > "$(BUILD)/edir-truncated.edir"
	cp "$(BUILD)/edir-fixture.edir" "$(BUILD)/edir-corrupt.edir"
	dd if=/dev/zero of="$(BUILD)/edir-corrupt.edir" bs=$(EDIR_FILE_CORRUPT_PREFIX_BYTES) count=$(EDIR_FILE_CORRUPT_PREFIX_BYTES) conv=notrunc 2>/dev/null
	dd if=/dev/zero of="$(BUILD)/edir-oversized.edir" bs=$(EDIR_FILE_TOO_LARGE_BYTES) count=1 2>/dev/null
	"$(BUILD)/elisa-debugger-edir-file-loader-check"

$(COMPILER_EDIR_INTEGRATION_CHECK): tests/compiler_edir_integration_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

# Run this separately from `smoke`: it requires an Elisa compiler checkout that
# implements `-emit edir`. Set ELISA_EDIR_COMPILER to that isolated checkout's
# stage1 wrapper; stale compiler products are rejected unless explicitly
# allowed with ELISA_EDIR_ALLOW_STALE_STAGE1=1. No non-Elisa fixture compiler
# or test runner is involved.
compiler-edir-check: $(COMPILER_EDIR_INTEGRATION_CHECK) $(BUILD)/elisa-debugger-dap-server
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit edir -O0 -o "$(COMPILER_EDIR_ARTIFACT)" "$(COMPILER_EDIR_FIXTURE)"
	"$(COMPILER_EDIR_INTEGRATION_CHECK)"
	compiler_dap_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(COMPILER_EDIR_ARTIFACT)"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stepIn"}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"scopes","arguments":{"frameId":1}}' '{"seq":9,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_DAP_LOCAL_REFERENCE)}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); compiler_dap_output=$$(printf %s "$$compiler_dap_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$compiler_dap_output" | grep -F '"name":"local0","value":"40","type":"i64"'
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit exe -O0 -o "$(COMPILER_NATIVE_ARTIFACT)" "$(COMPILER_EDIR_FIXTURE)"
	native_status=0; "$(COMPILER_NATIVE_ARTIFACT)" || native_status=$$?; test "$$native_status" -eq "$(COMPILER_EDIR_EXPECTED_EXIT)"

$(BUILD)/elisa-debugger-timeline-capability-check: tests/timeline_capability_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

timeline-capability-check: $(BUILD)/elisa-debugger-timeline-capability-check
	"$(BUILD)/elisa-debugger-timeline-capability-check"

ffi-check: $(BUILD)/elisa-debugger-ffi-probe
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

$(BUILD)/elisa-debugger-process-spawn-check: tests/process_spawn_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

process-spawn-check: $(BUILD)/elisa-debugger-process-spawn-check
	"$(BUILD)/elisa-debugger-process-spawn-check" $(PROCESS_SPAWN_CHECK_PARENT_MODE) $(PROCESS_SPAWN_CHECK_RESERVED_FIRST) $(PROCESS_SPAWN_CHECK_RESERVED_SECOND)

$(BUILD)/elisa-debugger: $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" src/main.elisa

$(BUILD)/elisa-debugger-server: src/protocol/server.elisa src/protocol/framing.elisa src/protocol/request.elisa src/protocol/dispatcher.elisa src/protocol/managed_service.elisa src/core/errors.elisa src/core/identity.elisa src/core/capabilities.elisa src/core/cancellation.elisa src/core/session.elisa src/core/events.elisa src/engine/coordinator.elisa src/engine/managed.elisa src/engine/default_image.elisa src/replay/engine.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-dap-server: src/protocol/dap_server.elisa src/protocol/dispatcher.elisa src/core/cancellation.elisa src/engine/coordinator.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-cli: src/cli/entrypoint.elisa src/protocol/dispatcher.elisa src/core/cancellation.elisa src/engine/coordinator.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-core-check: tests/module_core_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-data-check: tests/module_data_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-protocol-check: tests/module_protocol_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-codec-check: tests/trace_codec_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-recording-check: tests/trace_recording_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-bundle-check: tests/trace_bundle_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-codec-check: $(BUILD)/elisa-debugger-module-trace-codec-check
	"$(BUILD)/elisa-debugger-module-trace-codec-check"

trace-recording-check: $(BUILD)/elisa-debugger-module-trace-recording-check
	"$(BUILD)/elisa-debugger-module-trace-recording-check"

trace-bundle-check: $(BUILD)/elisa-debugger-module-trace-bundle-check
	"$(BUILD)/elisa-debugger-module-trace-bundle-check"

$(BUILD)/elisa-debugger-edir-call-check: tests/edir_call_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-edir-codec-check: tests/edir_codec_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-breakpoint-resolver-check: tests/breakpoint_resolver_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

breakpoint-resolver-check: $(BUILD)/elisa-debugger-breakpoint-resolver-check
	"$(BUILD)/elisa-debugger-breakpoint-resolver-check"

$(BUILD)/elisa-debugger-path-policy-check: tests/path_policy_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

path-policy-check: $(BUILD)/elisa-debugger-path-policy-check
	"$(BUILD)/elisa-debugger-path-policy-check"

edir-codec-check: $(BUILD)/elisa-debugger-edir-codec-check
	"$(BUILD)/elisa-debugger-edir-codec-check"

$(BUILD)/elisa-debugger-session-check: tests/session_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-ffi-probe: tests/ffi_probe.elisa
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-inspection-check: tests/managed_inspection_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-service-check: tests/managed_service_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-trace-service-check: tests/managed_trace_service_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-memory-write-history-check: tests/managed_memory_write_history_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

managed-memory-write-history-check: $(BUILD)/elisa-debugger-managed-memory-write-history-check
	"$(BUILD)/elisa-debugger-managed-memory-write-history-check"

$(BUILD)/elisa-debugger-protocol-events-check: tests/protocol_events_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-protocol-encoding-check: tests/protocol_encoding_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-protocol-framing-check: tests/protocol_framing_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

protocol-framing-check: $(BUILD)/elisa-debugger-protocol-framing-check
	"$(BUILD)/elisa-debugger-protocol-framing-check"

$(BUILD)/elisa-debugger-server-buffer-check: tests/server_buffer_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

server-buffer-check: $(BUILD)/elisa-debugger-server-buffer-check
	"$(BUILD)/elisa-debugger-server-buffer-check"

server-flush-check: $(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server
	sh tests/server_flush_check.sh "$(BUILD)/elisa-debugger-server" "$(BUILD)/elisa-debugger-dap-server"

$(BUILD)/elisa-debugger-trace-storage-decode-check: tests/trace_storage_decode_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-storage-decode-check: $(BUILD)/elisa-debugger-trace-storage-decode-check
	"$(BUILD)/elisa-debugger-trace-storage-decode-check"

$(BUILD)/elisa-debugger-trace-reader-encoded-check: tests/trace_reader_encoded_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-reader-encoded-check: $(BUILD)/elisa-debugger-trace-reader-encoded-check
	"$(BUILD)/elisa-debugger-trace-reader-encoded-check"

$(BUILD)/elisa-debugger-trace-checkpoint-validation-check: tests/trace_checkpoint_validation_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-checkpoint-validation-check: $(BUILD)/elisa-debugger-trace-checkpoint-validation-check
	"$(BUILD)/elisa-debugger-trace-checkpoint-validation-check"

$(BUILD)/elisa-debugger-remote-authentication-check: tests/remote_authentication_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

remote-authentication-check: $(BUILD)/elisa-debugger-remote-authentication-check
	"$(BUILD)/elisa-debugger-remote-authentication-check"

$(BUILD)/elisa-debugger-remote-artifacts-check: tests/remote_artifacts_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

remote-artifacts-check: $(BUILD)/elisa-debugger-remote-artifacts-check
	"$(BUILD)/elisa-debugger-remote-artifacts-check"

$(BUILD)/elisa-debugger-native-elf-check: tests/native_elf_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-elf-check: $(BUILD)/elisa-debugger-native-elf-check
	"$(BUILD)/elisa-debugger-native-elf-check"

$(BUILD)/elisa-debugger-native-macho-check: tests/native_macho_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macho-check: $(BUILD)/elisa-debugger-native-macho-check
	"$(BUILD)/elisa-debugger-native-macho-check"

$(BUILD)/elisa-debugger-native-artifact-check: tests/native_artifact_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-artifact-check: $(BUILD)/elisa-debugger-native-artifact-check
	"$(BUILD)/elisa-debugger-native-artifact-check"

$(BUILD)/elisa-debugger-native-symbols-identity-check: tests/native_symbols_identity_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-symbols-identity-check: $(BUILD)/elisa-debugger-native-symbols-identity-check
	"$(BUILD)/elisa-debugger-native-symbols-identity-check"

$(BUILD)/elisa-debugger-native-symbol-loader-check: tests/native_symbol_loader_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-symbol-loader-check: $(BUILD)/elisa-debugger-native-symbol-loader-check
	"$(BUILD)/elisa-debugger-native-symbol-loader-check"

$(BUILD)/elisa-debugger-native-controller-check: tests/native_controller_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-controller-check: $(BUILD)/elisa-debugger-native-controller-check
	"$(BUILD)/elisa-debugger-native-controller-check"

protocol-encoding-check: $(BUILD)/elisa-debugger-protocol-encoding-check
	"$(BUILD)/elisa-debugger-protocol-encoding-check"

$(BUILD)/elisa-debugger-checkpoint-state-check: tests/checkpoint_state_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

checkpoint-state-check: $(BUILD)/elisa-debugger-checkpoint-state-check
	"$(BUILD)/elisa-debugger-checkpoint-state-check"

$(BUILD)/elisa-debugger-full-checkpoint-codec-check: tests/full_checkpoint_codec_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

full-checkpoint-codec-check: $(BUILD)/elisa-debugger-full-checkpoint-codec-check
	"$(BUILD)/elisa-debugger-full-checkpoint-codec-check"

$(BUILD)/elisa-debugger-trace-manifest-status-check: tests/trace_manifest_status_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-manifest-status-check: $(BUILD)/elisa-debugger-trace-manifest-status-check
	"$(BUILD)/elisa-debugger-trace-manifest-status-check"

$(BUILD)/elisa-debugger-adapter-recording-bounds-check: tests/adapter_recording_bounds_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

adapter-recording-bounds-check: $(BUILD)/elisa-debugger-adapter-recording-bounds-check
	"$(BUILD)/elisa-debugger-adapter-recording-bounds-check"

$(BUILD)/elisa-debugger-runtime-status-check: tests/runtime_status_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

runtime-status-check: $(BUILD)/elisa-debugger-runtime-status-check
	"$(BUILD)/elisa-debugger-runtime-status-check"

$(BUILD)/elisa-debugger-source-store-check: tests/source_store_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-request-whitespace-check: tests/request_whitespace_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-cli-commands-check: tests/cli_commands_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-value-store-check: tests/value_store_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-historical-values-check: tests/historical_values_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-query-engine-check: tests/query_engine_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-query-evaluator-check: tests/query_evaluator_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-breakpoint-manager-check: tests/breakpoint_manager_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-advanced-analysis-check: tests/advanced_analysis_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-integration-contract-check: tests/integration_contract_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-integration-surface-check: tests/integration_surface_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

integration-surface-check: $(BUILD)/elisa-debugger-integration-surface-check
	"$(BUILD)/elisa-debugger-integration-surface-check"

$(BUILD)/elisa-debugger-trace-retention-check: tests/trace_retention_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-coordinator-seek-check: tests/coordinator_seek_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-capabilities-check: tests/capabilities_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

check: $(BUILD)/elisa-debugger
	"$(BUILD)/elisa-debugger"

smoke: check server dap-server cli cli-flush-check ffi-check edir-file-loader-check managed-source-path-check server-flush-check dap-command-check dap-frame-length-check
	dap_windows_case_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir","sourcePathRoot":"C:\\Workspace"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"c:\\workspace\\main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace"}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_windows_case_paths=$$(printf %s "$$dap_windows_case_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_windows_case_paths" | grep -F '"command":"setBreakpoints","success":true'; echo "$$dap_windows_case_paths" | grep -F '"source":{"name":"main.elisa","path":"C:/Workspace/main.elisa"}'; echo "$$dap_windows_case_paths" | grep -F '"reason":"breakpoint"'
	dap_unc_path_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir","sourcePathRoot":"\\\\server\\share"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"\\\\SERVER\\SHARE\\main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace"}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_unc_paths=$$(printf %s "$$dap_unc_path_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_unc_paths" | grep -F '"command":"setBreakpoints","success":true'; echo "$$dap_unc_paths" | grep -F '"source":{"name":"main.elisa","path":"//server/share/main.elisa"}'; echo "$$dap_unc_paths" | grep -F '"reason":"breakpoint"'
	printf '655360 ' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf '21 {' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf '$(IDLESS_LAUNCH_PAYLOAD_LENGTH) {"method":"launch"}\n' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 655360\r\n\r\n' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf '21 {"method":"discover"}\n' | "$(BUILD)/elisa-debugger-server" | grep -F '"protocolMajor":1' | grep -F '"productVersion":"0.1.0"' | grep -F '"sourceBreakpoints":false' | grep -F '"reverseExecution":true' | grep -F '"typedValues":true' | grep -F '"historicalQueries":false' | grep -F '"traceExport":false' | grep -F '"installationHealthy":true'
	server_timeline_input=$$(for payload in '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"reverseStep","id":4}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_timeline=$$(printf '%s\n' "$$server_timeline_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_timeline" | grep -F '"id":"3","ok":true'; echo "$$server_timeline" | grep -F '"id":"4","ok":true'; printf '%s\n' "$$server_timeline" | while IFS=' ' read -r declared payload; do test "$$declared" -eq "$$(printf %s "$$payload" | wc -c | tr -d ' ')"; done
	server_launch_state_input=$$(for payload in '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"launch","id":4,"expectedStopGeneration":$(SERVER_TEST_STALE_GENERATION),"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"launch","id":5,"expectedStopGeneration":$(SERVER_TEST_CURRENT_GENERATION),"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"stack","id":6}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_launch_state=$$(printf '%s\n' "$$server_launch_state_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_launch_state" | grep -F '"id":"4","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_launch_state" | grep -F '"id":"5","ok":false' | grep -F '"code":"INVALID_STATE"'; echo "$$server_launch_state" | grep -F '"id":"6","ok":true' | grep -F '"instruction":"$(SERVER_TEST_FIRST_STEP_INSTRUCTION)"' | grep -F '"accumulator":"$(SERVER_TEST_FIRST_STEP_ACCUMULATOR)"'
	server_inspection_input=$$(for payload in '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"step","id":4}' '{"method":"step","id":5}' '{"method":"step","id":6}' '{"method":"stack","id":7}' '{"method":"scopes","id":8}' '{"method":"variables","id":9,"arguments":{"variablesReference":"5"},"pageSize":$(SERVER_TEST_PAGE_SIZE),"pageStart":0}' '{"method":"variables","id":10,"arguments":{"variablesReference":"5"},"pageSize":$(SERVER_TEST_PAGE_SIZE),"pageStart":"1"}' '{"method":"variables","id":11,"arguments":{"variablesReference":"4"}}' '{"method":"threads","id":12}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_inspection=$$(printf '%s\n' "$$server_inspection_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_inspection" | grep -F '"id":"7","ok":true' | grep -F '"frame":{"name":"frame"'; echo "$$server_inspection" | grep -F '"id":"8","ok":true' | grep -F '"variablesReference"'; echo "$$server_inspection" | grep -F '"id":"9","ok":true' | grep -F '"name":"local0"' | grep -F '"value":"17"' | grep -F '"complete":false' | grep -F '"next":"1"'; echo "$$server_inspection" | grep -F '"id":"10","ok":true' | grep -F '"name":"local1"' | grep -F '"value":"29"' | grep -F '"complete":true' | grep -F '"next":null'; echo "$$server_inspection" | grep -F '"id":"11","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_inspection" | grep -F '"id":"12","ok":false'
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"supportsStepBack":true'
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"supportsEvaluateForHovers":false' | grep -F '"supportsDataBreakpoints":false'
	dap_initialize=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server"); dap_declared=$$(printf %s "$$dap_initialize" | sed -n 's/^Content-Length: //p' | tr -d '\r'); dap_body=$$(printf %s "$$dap_initialize" | sed -n '3p'); test "$$dap_declared" -eq "$$(printf %s "$$dap_body" | wc -c | tr -d ' ' )"
	dap_unwired=$$(printf 'Content-Length: 45\r\n\r\n{"seq":1,"type":"request","command":"launch"}Content-Length: 47\r\n\r\n{"seq":2,"type":"request","command":"evaluate"}Content-Length: 53\r\n\r\n{"seq":3,"type":"request","command":"setBreakpoints"}Content-Length: 57\r\n\r\n{"seq":4,"type":"request","command":"setDataBreakpoints"}Content-Length: 61\r\n\r\n{"seq":5,"type":"request","command":"setFunctionBreakpoints"}' | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_unwired" | grep -F '"command":"launch","success":false'; echo "$$dap_unwired" | grep -F '"command":"evaluate","success":false'; echo "$$dap_unwired" | grep -F '"command":"setBreakpoints","success":false'; echo "$$dap_unwired" | grep -F '"command":"setDataBreakpoints","success":false'; echo "$$dap_unwired" | grep -F '"command":"setFunctionBreakpoints","success":false'
	dap_unknown_payload='{"seq":1,"type":"request","command":"customRequest"}'; dap_unknown_length=$$(printf %s "$$dap_unknown_payload" | wc -c | tr -d ' '); dap_unknown=$$(printf 'Content-Length: %s\r\n\r\n%s' "$$dap_unknown_length" "$$dap_unknown_payload" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_unknown" | grep -F '"command":"customRequest","success":false'
	dap_escaped_command_payload='{"seq":1,"type":"request","command":"\u0069nitialize"}'; dap_escaped_command_length=$$(printf %s "$$dap_escaped_command_payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$dap_escaped_command_length" "$$dap_escaped_command_payload" | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"command":"initialize","success":true'
	dap_escaped_type_payload='{"seq":1,"type":"re\u0071uest","command":"initialize"}'; dap_escaped_type_length=$$(printf %s "$$dap_escaped_type_payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$dap_escaped_type_length" "$$dap_escaped_type_payload" | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"command":"initialize","success":true'
	dap_escaped_keys_payload='{"s\u0065q":1,"t\u0079pe":"request","com\u006dand":"initialize"}'; dap_escaped_keys_length=$$(printf %s "$$dap_escaped_keys_payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$dap_escaped_keys_length" "$$dap_escaped_keys_payload" | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"command":"initialize","success":true'
	dap_short_escape_payload='{"seq":1,"type":"request","command":"custom\/Request"}'; dap_short_escape_length=$$(printf %s "$$dap_short_escape_payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$dap_short_escape_length" "$$dap_short_escape_payload" | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"command":"custom\/Request","success":false'
	dap_unicode_command_prefix='{"seq":1,"type":"request","command":"custom'; dap_unicode_command_payload=$$dap_unicode_command_prefix$$(printf '\303\251')'"}'; dap_unicode_command_length=$$(printf %s "$$dap_unicode_command_payload" | wc -c | tr -d ' '); dap_unicode_command_response=$$(printf 'Content-Length: %s\r\n\r\n%s' "$$dap_unicode_command_length" "$$dap_unicode_command_payload" | "$(BUILD)/elisa-debugger-dap-server"); printf '%s\n' "$$dap_unicode_command_response" | grep -F "$$(printf '\303\251')" | grep -F '"success":false'
	dap_invalid_utf8_prefix='{"seq":1,"type":"request","command":"custom'; dap_invalid_utf8_payload=$$dap_invalid_utf8_prefix$$(printf '\377')'"}'; dap_invalid_utf8_length=$$(printf %s "$$dap_invalid_utf8_payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$dap_invalid_utf8_length" "$$dap_invalid_utf8_payload" | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 41\r\n\r\n{"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 48\r\n\r\n{"seq":1,"type":"request","command":"initialize"' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: $(DAP_ZERO_SEQUENCE_LAUNCH_PAYLOAD_LENGTH)\r\n\r\n{"seq":0,"type":"request","command":"launch"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":1,"type":"request","command":"initialize"}x' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":01,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1 "type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request" "command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 58\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":"\\q"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 61\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":notjson}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 73\r\n\r\n{"seq":1,"type":"request","arguments":{"x":"\\"command\\":\\"initialize\\""}}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	# Keep the escaped quote in the JSON payload: POSIX printf consumes one
	# backslash in its format string, so two are required in this test recipe.
	printf 'Content-Length: 55\r\n\r\n{"seq":1,"type":"request","command":"initialize\\"junk"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -q '"success":false'; test "$$?" -eq 0
	printf 'Content-Length: 55\r\n\r\n{"seq":1,"type":"request\"junk","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":1,"type":"request","command":"initialize",}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 56\r\n\r\n{"seq":1,"type":"request","command":"initialize",,"x":1}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 58\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":[{]}}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	launch_payload=' {"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir"}}'; launch_length=$$(printf %s "$$launch_payload" | wc -c | tr -d ' '); dap_fixture=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: %s\r\n\r\n%sContent-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 49\r\n\r\n{"seq":4,"type":"request","command":"stackTrace"}' "$$launch_length" "$$launch_payload" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_fixture" | grep -F '"command":"launch","success":true'; echo "$$dap_fixture" | grep -F '"stackFrames":[{"id":1,"name":"main","line":41,"column":$(DAP_EXPECTED_MAPPED_COLUMN)'
	initialize_payload='{"seq":1,"type":"request","command":"initialize","arguments":{"linesStartAt1":false,"columnsStartAt1":false}}'; initialize_length=$$(printf %s "$$initialize_payload" | wc -c | tr -d ' '); launch_payload='{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir"}}'; launch_length=$$(printf %s "$$launch_payload" | wc -c | tr -d ' '); dap_zero_based=$$(printf 'Content-Length: %s\r\n\r\n%sContent-Length: %s\r\n\r\n%sContent-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 49\r\n\r\n{"seq":4,"type":"request","command":"stackTrace"}' "$$initialize_length" "$$initialize_payload" "$$launch_length" "$$launch_payload" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_zero_based" | grep -F '"stackFrames":[{"id":1,"name":"main","line":$(DAP_ZERO_BASED_MAPPED_LINE),"column":$(DAP_ZERO_BASED_MAPPED_COLUMN)'
	dap_breakpoint_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir","sourcePathRoot":"/workspace"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"/workspace/missing.elisa"},"breakpoints":[]}}' '{"seq":4,"type":"request","command":"setBreakpoints","arguments":{"source":{"name":"main.elisa","path":"/workspace/main.elisa","sourceReference":0},"breakpoints":[{"line":42},{"line":99}]}}' '{"seq":5,"type":"request","command":"continue"}' '{"seq":6,"type":"request","command":"stackTrace"}' '{"seq":7,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"/workspace/main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":8,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":99},"breakpoints":[]}}' '{"seq":9,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":7,"path":"/workspace/missing.elisa"},"breakpoints":[]}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_source_breakpoints=$$(printf %s "$$dap_breakpoint_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_source_breakpoints" | grep -F '"command":"setBreakpoints","success":false'; echo "$$dap_source_breakpoints" | grep -F '"command":"setBreakpoints","success":true,"body":{"breakpoints":[{"id":1,"verified":true,"line":42},{"id":2,"verified":false,"line":99}]}}'; echo "$$dap_source_breakpoints" | grep -F '"source":{"name":"main.elisa","path":"/workspace/main.elisa"}'; echo "$$dap_source_breakpoints" | grep -F '"reason":"breakpoint"'; echo "$$dap_source_breakpoints" | grep -F '"stackFrames":[{"id":1,"name":"main","line":42,'
	dap_windows_path_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir","sourcePathRoot":"C:\\workspace"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"C:\\workspace\\main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace"}' '{"seq":6,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"C:/workspace/main.elisa"},"breakpoints":[{"line":42}]}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_windows_paths=$$(printf %s "$$dap_windows_path_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_windows_paths" | grep -F '"command":"setBreakpoints","success":true,"body":{"breakpoints":[{"id":1,"verified":true,"line":42}]}}'; echo "$$dap_windows_paths" | grep -F '"source":{"name":"main.elisa","path":"C:/workspace/main.elisa"}'; echo "$$dap_windows_paths" | grep -F '"reason":"breakpoint"'
	dap_zero_based_breakpoint_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize","arguments":{"linesStartAt1":false}}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":7},"breakpoints":[{"line":41}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace"}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_zero_based_breakpoints=$$(printf %s "$$dap_zero_based_breakpoint_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_zero_based_breakpoints" | grep -F '"command":"setBreakpoints","success":true,"body":{"breakpoints":[{"id":1,"verified":true,"line":41}]}}'; echo "$$dap_zero_based_breakpoints" | grep -F '"reason":"breakpoint"'; echo "$$dap_zero_based_breakpoints" | grep -F '"stackFrames":[{"id":1,"name":"main","line":41,'
	launch_payload='{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir"}}'; launch_length=$$(printf %s "$$launch_payload" | wc -c | tr -d ' '); dap_timeline=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: %s\r\n\r\n%sContent-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 43\r\n\r\n{"seq":4,"type":"request","command":"next"}Content-Length: 49\r\n\r\n{"seq":5,"type":"request","command":"stackTrace"}Content-Length: 47\r\n\r\n{"seq":6,"type":"request","command":"stepBack"}Content-Length: 49\r\n\r\n{"seq":7,"type":"request","command":"stackTrace"}Content-Length: 43\r\n\r\n{"seq":8,"type":"request","command":"next"}Content-Length: 49\r\n\r\n{"seq":9,"type":"request","command":"stackTrace"}Content-Length: 44\r\n\r\n{"seq":10,"type":"request","command":"next"}Content-Length: 50\r\n\r\n{"seq":11,"type":"request","command":"stackTrace"}' "$$launch_length" "$$launch_payload" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_timeline" | grep -F '"line":42,"column":$(DAP_EXPECTED_MAPPED_COLUMN)'; echo "$$dap_timeline" | grep -F '"line":41,"column":$(DAP_EXPECTED_MAPPED_COLUMN)'; echo "$$dap_timeline" | grep -F '"line":$(DAP_UNKNOWN_SOURCE_LINE),"column":$(DAP_UNKNOWN_SOURCE_LINE)}]}}'
	dap_variables_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stepIn"}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"scopes","arguments":{"frameId":1}}' '{"seq":9,"type":"request","command":"variables","arguments":{"variablesReference":5}}' '{"seq":10,"type":"request","command":"stepIn"}' '{"seq":11,"type":"request","command":"variables","arguments":{"variablesReference":5}}' '{"seq":12,"type":"request","command":"scopes","arguments":{"frameId":1}}' '{"seq":13,"type":"request","command":"variables","arguments":{"variablesReference":6}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_variables=$$(printf %s "$$dap_variables_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_variables" | grep -F '"variablesReference":5,"expensive":false'; echo "$$dap_variables" | grep -F '"name":"local0","value":"17","type":"i64"'; echo "$$dap_variables" | grep -F '"name":"local1","value":"29","type":"i64"'; echo "$$dap_variables" | grep -F '"command":"variables","success":false,"message":"variables reference is stale"'; echo "$$dap_variables" | grep -F '"variablesReference":6,"expensive":false'
	printf 'launch\npause\ncontinue\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'
	cli_inspection=$$(printf 'launch\npause\nstack\nlocals\n' | "$(BUILD)/elisa-debugger-cli"); echo "$$cli_inspection" | grep -F 'frame id='; echo "$$cli_inspection" | grep -F 'locals count=0'
	cli_unwired=$$(printf 'launch\npause\ntasks\nevaluate\nbreak\nwatch\n' | "$(BUILD)/elisa-debugger-cli"); test "$$(printf '%s\n' "$$cli_unwired" | grep -c '^error code=')" -eq 4
	printf 'launch\npause\nseek 1\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'
	cli_save_trace=$$(printf 'launch\npause\nsaveTrace\n' | "$(BUILD)/elisa-debugger-cli"); test "$$(printf '%s\n' "$$cli_save_trace" | grep -c '^ok generation=')" -eq 2 && printf '%s\n' "$$cli_save_trace" | tail -n 1 | grep -F 'error code='
	cli_replay=$$(printf 'launch\npause\nreplay\n' | "$(BUILD)/elisa-debugger-cli"); test "$$(printf '%s\n' "$$cli_replay" | grep -c '^ok generation=')" -eq 2 && printf '%s\n' "$$cli_replay" | tail -n 1 | grep -F 'error code='
	printf 'run\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=0'
	printf 'launch' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=0'
	printf 'launch\r\npause\r\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=1'

clean:
	rm -rf $(BUILD)

# Included Elisa modules must invalidate executable and test products too.
$(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server $(BUILD)/elisa-debugger-cli $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-edir-codec-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-managed-trace-service-check $(BUILD)/elisa-debugger-managed-memory-write-history-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-protocol-encoding-check $(BUILD)/elisa-debugger-protocol-framing-check $(BUILD)/elisa-debugger-remote-authentication-check $(BUILD)/elisa-debugger-trace-storage-decode-check $(BUILD)/elisa-debugger-trace-reader-encoded-check $(BUILD)/elisa-debugger-checkpoint-state-check $(BUILD)/elisa-debugger-trace-manifest-status-check $(BUILD)/elisa-debugger-adapter-recording-bounds-check $(BUILD)/elisa-debugger-runtime-status-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-request-operands-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-integration-surface-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check: $(shell find src -type f -name '*.elisa')
