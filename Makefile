# Failed recipes must not leave partial executables that Make would later treat
# as current targets.
.DELETE_ON_ERROR:

ELISA_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
ELISA_COMPILER_COMMAND := $(ELISA_COMPILER)
# The compiler is commonly located under a workspace path containing spaces.
# Keep it as one shell argument in every recipe, including command-line
# overrides such as `make ELISA_COMPILER=/path/with\ spaces/elisac-stage1`.
override ELISA_COMPILER := "$(ELISA_COMPILER_COMMAND)"
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
DAP_STACK_FRAME_ID_STRIDE := 18
DAP_STACK_FRAME_ID_FIRST_OFFSET := 1
DAP_LOCALS_REFERENCE_STRIDE := 17
DAP_FIRST_STOP_GENERATION := 1
DAP_FIRST_STOP_FRAME_ID := $(shell expr $(DAP_FIRST_STOP_GENERATION) \* $(DAP_STACK_FRAME_ID_STRIDE) + $(DAP_STACK_FRAME_ID_FIRST_OFFSET))
COMPILER_EDIR_DAP_STOP_GENERATION := 5
COMPILER_EDIR_DAP_FRAME_ID := $(shell expr $(COMPILER_EDIR_DAP_STOP_GENERATION) \* $(DAP_STACK_FRAME_ID_STRIDE) + $(DAP_STACK_FRAME_ID_FIRST_OFFSET))
COMPILER_EDIR_DAP_LOCAL_REFERENCE := $(shell expr $(COMPILER_EDIR_DAP_STOP_GENERATION) \* $(DAP_LOCALS_REFERENCE_STRIDE))
COMPILER_EDIR_LOOP_FIXTURE := tests/compiler_edir_counted_loop_fixture.elisa
COMPILER_EDIR_LOOP_ARTIFACT := $(BUILD)/compiler_edir_counted_loop.edir
COMPILER_EDIR_LOOP_NATIVE_ARTIFACT := $(BUILD)/compiler_edir_counted_loop_native
COMPILER_EDIR_LOOP_INTEGRATION_CHECK := $(BUILD)/elisa-debugger-compiler-edir-counted-loop-check
COMPILER_EDIR_LOOP_EXPECTED_EXIT := 10
COMPILER_EDIR_LOOP_BREAKPOINT_LINE := 5
COMPILER_EDIR_LOOP_DAP_INITIAL_STOP_GENERATION := $(DAP_FIRST_STOP_GENERATION)
# Current optimized compiler EDIR lowering emits multiple replay events per
# source-level step. Keep DAP handles aligned with this fixture's stop generations.
COMPILER_EDIR_LOOP_DAP_STEPPED_STOP_GENERATION := 11
COMPILER_EDIR_LOOP_DAP_REVERSED_STOP_GENERATION := 12
COMPILER_EDIR_LOOP_DAP_INITIAL_FRAME_ID := $(DAP_FIRST_STOP_FRAME_ID)
COMPILER_EDIR_LOOP_DAP_STEPPED_FRAME_ID := $(shell expr $(COMPILER_EDIR_LOOP_DAP_STEPPED_STOP_GENERATION) \* $(DAP_STACK_FRAME_ID_STRIDE) + $(DAP_STACK_FRAME_ID_FIRST_OFFSET))
COMPILER_EDIR_LOOP_DAP_REVERSED_FRAME_ID := $(shell expr $(COMPILER_EDIR_LOOP_DAP_REVERSED_STOP_GENERATION) \* $(DAP_STACK_FRAME_ID_STRIDE) + $(DAP_STACK_FRAME_ID_FIRST_OFFSET))
COMPILER_EDIR_LOOP_DAP_INITIAL_LOCALS_REFERENCE := $(shell expr $(COMPILER_EDIR_LOOP_DAP_INITIAL_STOP_GENERATION) \* $(DAP_LOCALS_REFERENCE_STRIDE))
COMPILER_EDIR_LOOP_DAP_STEPPED_LOCALS_REFERENCE := $(shell expr $(COMPILER_EDIR_LOOP_DAP_STEPPED_STOP_GENERATION) \* $(DAP_LOCALS_REFERENCE_STRIDE))
COMPILER_EDIR_LOOP_DAP_REVERSED_LOCALS_REFERENCE := $(shell expr $(COMPILER_EDIR_LOOP_DAP_REVERSED_STOP_GENERATION) \* $(DAP_LOCALS_REFERENCE_STRIDE))
DAP_VARIABLES_AFTER_STEP_STOP_GENERATION := 6
DAP_VARIABLES_AFTER_STEP_FRAME_ID := $(shell expr $(DAP_VARIABLES_AFTER_STEP_STOP_GENERATION) \* $(DAP_STACK_FRAME_ID_STRIDE) + $(DAP_STACK_FRAME_ID_FIRST_OFFSET))
DAP_VARIABLES_AFTER_STEP_REFERENCE := $(shell expr $(DAP_VARIABLES_AFTER_STEP_STOP_GENERATION) \* $(DAP_LOCALS_REFERENCE_STRIDE))
MANAGED_ALLOCATIONS_CHECK := $(BUILD)/elisa-debugger-managed-allocations-check
CONCURRENCY_RACES_CHECK := $(BUILD)/elisa-debugger-concurrency-races-check
EXPRESSION_PARSER_CHECK := $(BUILD)/elisa-debugger-expression-parser-check
COMPILER_EDIR_CALLS_FIXTURE := tests/compiler_edir_calls_fixture.elisa
COMPILER_EDIR_CALLS_ARTIFACT := $(BUILD)/compiler_edir_calls.edir
COMPILER_EDIR_CALLS_CHECK := $(BUILD)/elisa-debugger-compiler-edir-calls-check
COMPILER_EDIR_CALLS_NATIVE_ARTIFACT := $(BUILD)/compiler_edir_calls_native
COMPILER_EDIR_CALLS_EXPECTED_EXIT := 52
COMPILER_EDIR_CALLS_EDIR_OPTIMIZATION_LEVEL := 0
COMPILER_EDIR_CALLS_NATIVE_OPTIMIZATION_LEVEL := 2
COMPILER_EDIR_CALLS_NATIVE_SUCCESS_STATUS := 0
COMPILER_EDIR_CORE_IR_FIXTURE := tests/compiler_edir_core_ir_fixture.elisa
COMPILER_EDIR_CORE_IR_ARTIFACT := $(BUILD)/compiler_edir_core_ir.edir
COMPILER_EDIR_CORE_IR_CHECK := $(BUILD)/elisa-debugger-compiler-edir-core-ir-check
COMPILER_EDIR_CORE_IR_LLVM := $(BUILD)/compiler_edir_core_ir.ll
COMPILER_EDIR_CORE_IR_NATIVE_O0 := $(BUILD)/compiler_edir_core_ir_native_o0
COMPILER_EDIR_CORE_IR_NATIVE_O2 := $(BUILD)/compiler_edir_core_ir_native_o2
COMPILER_EDIR_CORE_IR_EXPECTED_EXIT := 42
COMPILER_EDIR_CORE_IR_LLVM_MARKER := core.add
DAP_STACK_FRAMES_CHECK := $(BUILD)/elisa-debugger-dap-stack-frames-check
ELF_DWARF_LINE_CC ?= clang
ELF_DWARF_LINE_FIXTURE_SOURCE := tests/native_elf_dwarf_line_fixture.c
ELF_DWARF_LINE_FIXTURE := $(BUILD)/native-elf-dwarf-line-fixture
ifeq ($(shell uname -s),Darwin)
ELF_DWARF_LINE_TARGET_FLAGS := -target x86_64-unknown-linux-gnu -fuse-ld=lld
else
ELF_DWARF_LINE_TARGET_FLAGS :=
endif
PROCESS_SPAWN_CHECK_PARENT_MODE := --process-check-parent
PROCESS_SPAWN_CHECK_RESERVED_FIRST := reserved-first
PROCESS_SPAWN_CHECK_RESERVED_SECOND := reserved-second
IDLESS_LAUNCH_PAYLOAD_LENGTH := 19
DAP_ZERO_SEQUENCE_LAUNCH_PAYLOAD_LENGTH := 45
SERVER_TEST_PAGE_SIZE := 1
SERVER_TEST_STALE_GENERATION := 1
SERVER_TEST_CURRENT_GENERATION := 2
SERVER_TEST_EVALUATE_VALUE := 46
SERVER_TEST_EVALUATE_CONSUMED_BYTES := 15
SERVER_TEST_FIRST_STEP_INSTRUCTION := 1
SERVER_TEST_FIRST_STEP_ACCUMULATOR := 17
SERVER_TEST_SOURCE_BREAKPOINT_LINE := 42
SERVER_TEST_LOGPOINT_LINE := 44
SERVER_TEST_CALLEE_SOURCE_LINE := 47
SERVER_TEST_UNRESOLVED_BREAKPOINT_LINE := 99
SERVER_TEST_BREAKPOINT_INSTRUCTION := 1
SERVER_TEST_STALE_BREAKPOINT_GENERATION := 0
SERVER_PROTOCOL_MAJOR := 1
SERVER_PROTOCOL_MINOR := 0
SERVER_NEWER_MINOR_REQUEST := 17
SERVER_INCOMPATIBLE_MAJOR := 2
SERVER_OWNER_SESSION_ID := 1
SERVER_OWNER_TOKEN := 1
SERVER_INITIALIZE_PAYLOAD := {"method":"initialize","id":99,"protocolMajor":$(SERVER_PROTOCOL_MAJOR),"protocolMinor":$(SERVER_PROTOCOL_MINOR)}
EDIR_FILE_TOO_LARGE_BYTES := 37730
EDIR_FILE_TRUNCATED_BYTES := 5
EDIR_FILE_CORRUPT_PREFIX_BYTES := 1
DAP_UNKNOWN_SOURCE_LINE := 0
DAP_EXPECTED_MAPPED_COLUMN := 4
DAP_ZERO_BASED_MAPPED_LINE := 40
DAP_ZERO_BASED_MAPPED_COLUMN := 3
# Require the sibling checkout's current stage1 executable by default. The wrapper
# also rejects it when any compiler source is newer than the executable.
ELISA_ALLOW_STALE_STAGE1 ?= 0
ELISA_COMPILER_SOURCE_ROOT ?= ../Elisa-compiler
ELISA_COMPILER_WRAPPER_BUILD_DEPENDENCY ?= $(ELISA_COMPILER_SOURCE_ROOT)/scripts/elisac_stage1.sh
ELISA_COMPILER_BUILD_DEPENDENCY ?= $(if $(ELISA_STAGE1_BIN),$(ELISA_STAGE1_BIN),$(ELISA_COMPILER_SOURCE_ROOT)/bin/elisac-stage1)
ELISA_RUNTIME_BUILD_DEPENDENCY ?= $(ELISA_RUNTIME)
# Track a compiler command that names a local path even when it differs from the
# default checkout. Bare command names resolved through PATH have no make path.
ELISA_COMPILER_COMMAND_BUILD_DEPENDENCY ?= $(if $(findstring /,$(ELISA_COMPILER_COMMAND)),$(ELISA_COMPILER_COMMAND))
# Elisa's stage1 compiler does not emit make dependency files for `include`d
# modules. Keep focused checks dependent on every source module and the compiler
# sources, executable, and linked runtime so changes cannot leave stale binaries.
# The compiler source root and executable dependency can be overridden together
# when using a custom compiler checkout or ELISA_STAGE1_BIN.
ELISA_EMPTY :=
ELISA_SPACE := $(ELISA_EMPTY) $(ELISA_EMPTY)
ELISA_ESCAPE_PATH = $(subst $(ELISA_SPACE),\$(ELISA_SPACE),$(1))
ELISA_SOURCE_FILES := $(shell find src -type f -name '*.elisa')
ELISA_COMPILER_SOURCE_FILES := $(shell find "$(ELISA_COMPILER_SOURCE_ROOT)/src" "$(ELISA_COMPILER_SOURCE_ROOT)/elisacore_std" -type f \( -name '*.elisa' -o -name '*.elisai' \) -print0 2>/dev/null | python3 -c 'import sys; paths = sys.stdin.buffer.read().split(b"\0"); print(" ".join(path.decode().replace(" ", "\\ ") for path in paths if path))')
ELISA_COMPILER_BUILD_INPUTS := $(ELISA_COMPILER_SOURCE_FILES) $(call ELISA_ESCAPE_PATH,$(ELISA_COMPILER_COMMAND_BUILD_DEPENDENCY)) $(call ELISA_ESCAPE_PATH,$(ELISA_COMPILER_WRAPPER_BUILD_DEPENDENCY)) $(call ELISA_ESCAPE_PATH,$(ELISA_COMPILER_BUILD_DEPENDENCY)) $(call ELISA_ESCAPE_PATH,$(ELISA_RUNTIME_BUILD_DEPENDENCY))
ELISA_BUILD_INPUTS := $(ELISA_SOURCE_FILES) $(ELISA_COMPILER_BUILD_INPUTS)

.PHONY: cli-flush-check concurrency-scheduler-check native-breakpoint-lifecycle-check dap-logpoints-check dap-function-breakpoints-check effect-oracle-check
.PHONY: trace-file-check
.PHONY: remote-authorization-check server-version-check server-ownership-check compiler-edir-loop-check compiler-edir-calls-check compiler-edir-calls-unsupported-check compiler-edir-core-ir-check
.PHONY: protocol-client-ordering-check session-ownership-check
.PHONY: replay-seek-atomicity-check
.PHONY: dap-continue-partial-check
.PHONY: dap-stack-frames-check dap-stack-frame-check
.PHONY: metadata-names-check
.PHONY: managed-allocations-check concurrency-races-check expression-parser-check timeline-capability-check type-metadata-check
.PHONY: build-runner-check
.PHONY: native-jetsam-check native-jetsam-tool native-macos-resources-check native-macos-resources-tool native-agent-controller-check
.PHONY: native-macos-memory-check native-macos-memory-tool native-macos-attach-check
.PHONY: native-local-ipc-check
.PHONY: native-local-agent-transport-check
.PHONY: native-dwarf-line-check native-elf-dwarf-line-check
.PHONY: native-macho-dwarf-line-check
.PHONY: agent-wire-check agent-wire-stream-check agent-handshake-check agent-control-check agent-control-stream-check agent-session-transport-check
.PHONY: agent-thread-rendezvous-check
.PHONY: agent-async-session-transport-check
.PHONY: agent-shadow-frames-check
.PHONY: agent-inspection-rendezvous-check
.PHONY: agent-snapshot-wire-check
.PHONY: agent-value-codec-check

build: $(BUILD)/elisa-debugger

server: $(BUILD)/elisa-debugger-server

server-version-check: $(BUILD)/elisa-debugger-server edir-file-loader-check
	server_preinit_payload='{"method":"launch","id":40,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}'; server_preinit_length=$$(printf %s "$$server_preinit_payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$server_preinit_length" "$$server_preinit_payload" | "$(BUILD)/elisa-debugger-server" | grep -F '"id":"40","ok":false' | grep -F '"code":"INITIALIZE_REQUIRED"'
	server_initialize_input=$$(for payload in '{"method":"initialize","id":41,"protocolMajor":$(SERVER_INCOMPATIBLE_MAJOR),"protocolMinor":$(SERVER_PROTOCOL_MINOR)}' '{"method":"launch","id":48,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"initialize","id":44,"protocolMajor":$(SERVER_PROTOCOL_MAJOR)}' '{"method":"launch","id":49,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"initialize","id":42,"protocolMajor":$(SERVER_PROTOCOL_MAJOR),"protocolMinor":$(SERVER_PROTOCOL_MINOR)}' '{"method":"initialize","id":43,"protocolMajor":$(SERVER_PROTOCOL_MAJOR),"protocolMinor":$(SERVER_NEWER_MINOR_REQUEST)}' '{"method":"launch","id":45,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":46}' '{"method":"stack","id":47}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_initialize_output=$$(printf '%s\n' "$$server_initialize_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_initialize_output" | grep -F '"id":"41","ok":false' | grep -F '"code":"INCOMPATIBLE_VERSION"' | grep -F '"requestedProtocolMajor":$(SERVER_INCOMPATIBLE_MAJOR)' | grep -F '"serverProtocolMajor":$(SERVER_PROTOCOL_MAJOR)'; echo "$$server_initialize_output" | grep -F '"id":"48","ok":false' | grep -F '"code":"INITIALIZE_REQUIRED"'; echo "$$server_initialize_output" | grep -F '"id":"44","ok":false' | grep -F '"code":"INVALID_ARGUMENT"' | grep -F 'protocolMajor and protocolMinor'; echo "$$server_initialize_output" | grep -F '"id":"49","ok":false' | grep -F '"code":"INITIALIZE_REQUIRED"'; echo "$$server_initialize_output" | grep -F '"id":"42","ok":true' | grep -F '"protocolMajor":$(SERVER_PROTOCOL_MAJOR)' | grep -F '"protocolMinor":$(SERVER_PROTOCOL_MINOR)'; echo "$$server_initialize_output" | grep -F '"id":"43","ok":true' | grep -F '"protocolMinor":$(SERVER_PROTOCOL_MINOR)'; echo "$$server_initialize_output" | grep -F '"id":"45","ok":true'; echo "$$server_initialize_output" | grep -F '"id":"47","ok":true'

server-ownership-check: $(BUILD)/elisa-debugger-server edir-file-loader-check
	set -e; server_ownership_input=$$(for payload in '{"method":"initialize","id":1,"protocolMajor":$(SERVER_PROTOCOL_MAJOR),"protocolMinor":$(SERVER_PROTOCOL_MINOR)}' '{"method":"createSession","id":2}' '{"method":"launch","id":3,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"launch","id":4,"sessionId":"$(SERVER_OWNER_SESSION_ID)","ownerToken":"$(SERVER_OWNER_TOKEN)","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":5,"sessionId":"$(SERVER_OWNER_SESSION_ID)","ownerToken":"2"}' '{"method":"pause","id":6,"sessionId":"$(SERVER_OWNER_SESSION_ID)","ownerToken":"$(SERVER_OWNER_TOKEN)"}' '{"method":"stack","id":7,"sessionId":"$(SERVER_OWNER_SESSION_ID)"}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_ownership_output=$$(printf '%s\n' "$$server_ownership_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_ownership_output" | grep -F '"id":"2","ok":true' | grep -F '"sessionId":"$(SERVER_OWNER_SESSION_ID)"' | grep -F '"ownerToken":"$(SERVER_OWNER_TOKEN)"'; echo "$$server_ownership_output" | grep -F '"id":"3","ok":false' | grep -F '"code":"PERMISSION_DENIED"'; echo "$$server_ownership_output" | grep -F '"id":"4","ok":true'; echo "$$server_ownership_output" | grep -F '"id":"5","ok":false' | grep -F '"code":"PERMISSION_DENIED"'; echo "$$server_ownership_output" | grep -F '"id":"6","ok":true'; echo "$$server_ownership_output" | grep -F '"id":"7","ok":true'

.PHONY: server-source-breakpoints-check
.PHONY: server-evaluate-check
server-source-breakpoints-check: $(BUILD)/elisa-debugger-server edir-file-loader-check
	printf '21 {"method":"discover"}\n' | "$(BUILD)/elisa-debugger-server" | grep -F '"sourceBreakpoints":true'
	set -e; server_breakpoint_input=$$(for payload in '$(SERVER_INITIALIZE_PAYLOAD)' '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"setBreakpoints","id":2,"arguments":{"source":{"path":"main.elisa"},"breakpoints":[{"line":$(SERVER_TEST_SOURCE_BREAKPOINT_LINE)},{"line":$(SERVER_TEST_UNRESOLVED_BREAKPOINT_LINE)}]}}' '{"method":"setBreakpoints","id":3,"arguments":{"source":{"path":"main.elisa"},"breakpoints":[{"line":$(SERVER_TEST_SOURCE_BREAKPOINT_LINE),"condition":"false"}]}}' '{"method":"continue","id":4}' '{"method":"stack","id":5}' '{"method":"setBreakpoints","id":6,"expectedStopGeneration":"$(SERVER_TEST_STALE_BREAKPOINT_GENERATION)","arguments":{"source":{"path":"main.elisa"},"breakpoints":[]}}' '{"method":"setBreakpoints","id":7,"arguments":{"source":{"path":"missing.elisa"},"breakpoints":[]}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_breakpoint_output=$$(printf '%s\n' "$$server_breakpoint_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_breakpoint_output" | grep -F '"id":"2","ok":true' | grep -F '"breakpoints":[{"id":"1","line":$(SERVER_TEST_SOURCE_BREAKPOINT_LINE),"verified":true},{"id":"2","line":$(SERVER_TEST_UNRESOLVED_BREAKPOINT_LINE),"verified":false}]'; echo "$$server_breakpoint_output" | grep -F '"id":"3","ok":false' | grep -F '"code":"INVALID_ARGUMENT"'; echo "$$server_breakpoint_output" | grep -F '"id":"4","ok":true'; echo "$$server_breakpoint_output" | grep -F '"id":"5","ok":true' | grep -F '"instruction":"$(SERVER_TEST_BREAKPOINT_INSTRUCTION)"'; echo "$$server_breakpoint_output" | grep -F '"id":"6","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_breakpoint_output" | grep -F '"id":"7","ok":false' | grep -F '"code":"INVALID_ARGUMENT"'

server-evaluate-check: $(BUILD)/elisa-debugger-server edir-file-loader-check
	set -e; server_evaluate_input=$$(for payload in '$(SERVER_INITIALIZE_PAYLOAD)' '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"step","id":4}' '{"method":"step","id":5}' '{"method":"step","id":6}' '{"method":"evaluate","id":7,"arguments":{"expression":"local0 + local1","frameIndex":0}}' '{"method":"evaluate","id":8,"expectedStopGeneration":"$(SERVER_TEST_STALE_GENERATION)","arguments":{"expression":"local0 + local1"}}' '{"method":"evaluate","id":9,"arguments":{"expression":"1 / 0"}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_evaluate_output=$$(printf '%s\n' "$$server_evaluate_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_evaluate_output" | grep -F '"id":"7","ok":true' | grep -F '"evaluation":{"type":"i64","value":"$(SERVER_TEST_EVALUATE_VALUE)","consumed":$(SERVER_TEST_EVALUATE_CONSUMED_BYTES)}'; echo "$$server_evaluate_output" | grep -F '"id":"8","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_evaluate_output" | grep -F '"id":"9","ok":false' | grep -F '"code":"INVALID_ARGUMENT"'

dap-server: $(BUILD)/elisa-debugger-dap-server

dap-logpoints-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	sh tests/dap_logpoints_check.sh "$(BUILD)/elisa-debugger-dap-server" "$(BUILD)/edir-fixture.edir" "$(SERVER_TEST_LOGPOINT_LINE)"
	sh tests/dap_step_in_check.sh "$(BUILD)/elisa-debugger-dap-server" "$(BUILD)/edir-fixture.edir" "$(SERVER_TEST_CALLEE_SOURCE_LINE)"

dap-function-breakpoints-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	sh tests/dap_function_breakpoints_check.sh "$(BUILD)/elisa-debugger-dap-server" "$(BUILD)/edir-fixture.edir"

cli: $(BUILD)/elisa-debugger-cli

cli-flush-check: $(BUILD)/elisa-debugger-cli
	sh tests/cli_flush_check.sh "$(BUILD)/elisa-debugger-cli"

module-check: $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-edir-codec-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-managed-trace-service-check $(BUILD)/elisa-debugger-managed-memory-write-history-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-protocol-encoding-check $(BUILD)/elisa-debugger-protocol-framing-check $(BUILD)/elisa-debugger-remote-authentication-check $(BUILD)/elisa-debugger-remote-authorization-check $(BUILD)/elisa-debugger-trace-storage-decode-check $(BUILD)/elisa-debugger-trace-reader-encoded-check $(BUILD)/elisa-debugger-checkpoint-state-check $(BUILD)/elisa-debugger-trace-manifest-status-check $(BUILD)/elisa-debugger-adapter-recording-bounds-check $(BUILD)/elisa-debugger-effect-oracle-check $(BUILD)/elisa-debugger-runtime-status-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-request-operands-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-query-evaluator-check $(BUILD)/elisa-debugger-breakpoint-manager-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-integration-surface-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check $(BUILD)/elisa-debugger-dap-payload-check $(BUILD)/elisa-debugger-ffi-probe $(BUILD)/elisa-debugger-path-policy-check $(BUILD)/elisa-debugger-process-spawn-check $(BUILD)/elisa-debugger-build-runner-check
module-check: concurrency-scheduler-check
module-check: $(CONCURRENCY_RACES_CHECK)
module-check: $(EXPRESSION_PARSER_CHECK)
module-check: native-breakpoint-lifecycle-check
module-check: native-agent-controller-check
module-check: agent-wire-check
module-check: agent-wire-stream-check
module-check: agent-handshake-check
module-check: agent-control-check
module-check: agent-control-stream-check
module-check: agent-session-transport-check
module-check: agent-async-session-transport-check
module-check: agent-shadow-frames-check
module-check: agent-inspection-rendezvous-check
module-check: agent-snapshot-wire-check
module-check: agent-value-codec-check
module-check: agent-thread-rendezvous-check
ifneq ($(filter Darwin Linux,$(shell uname -s)),)
module-check: native-local-ipc-check
module-check: native-local-agent-transport-check
endif
module-check: dap-function-breakpoints-check
module-check: dap-native-frames-check
module-check: dap-native-variables-check dap-native-variables-json-check
module-check: metadata-names-check
module-check: $(BUILD)/elisa-debugger-timeline-capability-check
module-check: $(MANAGED_ALLOCATIONS_CHECK)

# Keep the remote artifact transfer regression in the aggregate module gate.
module-check: $(BUILD)/elisa-debugger-remote-artifacts-check
module-check: trace-file-check
module-check: $(BUILD)/elisa-debugger-native-elf-check
module-check: $(BUILD)/elisa-debugger-native-macho-check
module-check: $(BUILD)/elisa-debugger-native-dwarf-line-check
module-check: $(BUILD)/elisa-debugger-native-elf-dwarf-line-check
module-check: $(BUILD)/elisa-debugger-native-macho-dwarf-line-check
module-check: $(BUILD)/elisa-debugger-native-artifact-check
module-check: $(BUILD)/elisa-debugger-native-jetsam-check
ifeq ($(shell uname -s),Darwin)
module-check: $(BUILD)/elisa-debugger-native-macos-resources-check
module-check: $(BUILD)/elisa-debugger-native-macos-memory-check
module-check: $(BUILD)/elisa-debugger-native-macos-attach-check
endif
module-check: $(BUILD)/elisa-debugger-native-symbols-identity-check
module-check: $(BUILD)/elisa-debugger-native-symbol-loader-check
module-check: server-source-breakpoints-check
module-check: server-evaluate-check
module-check: dap-logpoints-check
module-check: server-ownership-check
module-check: $(BUILD)/elisa-debugger-replay-branches-check
module-check: $(BUILD)/elisa-debugger-replay-provenance-check
module-check: $(BUILD)/elisa-debugger-replay-seek-atomicity-check
module-check: $(BUILD)/elisa-debugger-state-integrity-check
module-check: $(BUILD)/elisa-debugger-trace-checkpoint-validation-check
module-check: $(BUILD)/elisa-debugger-full-checkpoint-codec-check
module-check: $(BUILD)/elisa-debugger-managed-memory-write-history-check
module-check: $(BUILD)/elisa-debugger-dap-events-check $(BUILD)/elisa-debugger-dap-continue-partial-check
module-check: $(DAP_STACK_FRAMES_CHECK)
module-check: dap-column-breakpoints-check
module-check: $(BUILD)/elisa-debugger-protocol-client-ordering-check
module-check: $(BUILD)/elisa-debugger-session-ownership-check
module-check: edir-file-loader-check
module-check: $(BUILD)/elisa-debugger-type-metadata-check

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
	"$(BUILD)/elisa-debugger-timeline-capability-check"
	"$(MANAGED_ALLOCATIONS_CHECK)"
	"$(CONCURRENCY_RACES_CHECK)"
	"$(EXPRESSION_PARSER_CHECK)"
	"$(DAP_STACK_FRAMES_CHECK)"
	"$(BUILD)/elisa-debugger-managed-service-check"
	"$(BUILD)/elisa-debugger-managed-trace-service-check"
	"$(BUILD)/elisa-debugger-managed-memory-write-history-check"
	"$(BUILD)/elisa-debugger-protocol-events-check"
	"$(BUILD)/elisa-debugger-protocol-client-ordering-check"
	"$(BUILD)/elisa-debugger-protocol-encoding-check"
	"$(BUILD)/elisa-debugger-protocol-framing-check"
	"$(BUILD)/elisa-debugger-trace-storage-decode-check"
	"$(BUILD)/elisa-debugger-trace-reader-encoded-check"
	"$(BUILD)/elisa-debugger-trace-checkpoint-validation-check"
	"$(BUILD)/elisa-debugger-remote-authentication-check"
	"$(BUILD)/elisa-debugger-remote-authorization-check"
	"$(BUILD)/elisa-debugger-remote-artifacts-check"
	"$(BUILD)/elisa-debugger-native-elf-check"
	"$(BUILD)/elisa-debugger-native-macho-check"
	"$(BUILD)/elisa-debugger-native-dwarf-line-check"
	"$(BUILD)/elisa-debugger-native-elf-dwarf-line-check"
	"$(BUILD)/elisa-debugger-native-macho-dwarf-line-check"
	"$(BUILD)/elisa-debugger-native-artifact-check"
	"$(BUILD)/elisa-debugger-native-jetsam-check"
ifeq ($(shell uname -s),Darwin)
	"$(BUILD)/elisa-debugger-native-macos-resources-check"
	"$(BUILD)/elisa-debugger-native-macos-memory-check"
	"$(BUILD)/elisa-debugger-native-macos-attach-check"
endif
	"$(BUILD)/elisa-debugger-native-symbols-identity-check"
	"$(BUILD)/elisa-debugger-native-symbol-loader-check"
	"$(BUILD)/elisa-debugger-native-agent-controller-check"
	"$(BUILD)/elisa-debugger-checkpoint-state-check"
	"$(BUILD)/elisa-debugger-full-checkpoint-codec-check"
	"$(BUILD)/elisa-debugger-dap-events-check"
	"$(BUILD)/elisa-debugger-dap-continue-partial-check"
	"$(BUILD)/elisa-debugger-replay-provenance-check"
	"$(BUILD)/elisa-debugger-replay-seek-atomicity-check"
	"$(BUILD)/elisa-debugger-replay-branches-check"
	"$(BUILD)/elisa-debugger-state-integrity-check"
	"$(BUILD)/elisa-debugger-trace-manifest-status-check"
	"$(BUILD)/elisa-debugger-adapter-recording-bounds-check"
	"$(BUILD)/elisa-debugger-effect-oracle-check"
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
	"$(BUILD)/elisa-debugger-build-runner-check"
	"$(BUILD)/elisa-debugger-type-metadata-check"
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

managed-inspection-check: $(BUILD)/elisa-debugger-managed-inspection-check
	"$(BUILD)/elisa-debugger-managed-inspection-check"

managed-service-check: $(BUILD)/elisa-debugger-managed-service-check
	"$(BUILD)/elisa-debugger-managed-service-check"

managed-trace-service-check: $(BUILD)/elisa-debugger-managed-trace-service-check
	"$(BUILD)/elisa-debugger-managed-trace-service-check"

managed-source-path-check: $(BUILD)/elisa-debugger-managed-source-path-check
	"$(BUILD)/elisa-debugger-managed-source-path-check"

$(BUILD)/elisa-debugger-managed-source-path-check: tests/managed_source_path_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-terminal-checkpoint-check: tests/terminal_checkpoint_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

terminal-checkpoint-check: $(BUILD)/elisa-debugger-terminal-checkpoint-check
	"$(BUILD)/elisa-debugger-terminal-checkpoint-check"

protocol-events-check: $(BUILD)/elisa-debugger-protocol-events-check
	"$(BUILD)/elisa-debugger-protocol-events-check"

source-store-check: $(BUILD)/elisa-debugger-source-store-check
	"$(BUILD)/elisa-debugger-source-store-check"

$(BUILD)/elisa-debugger-replay-branches-check: tests/replay_branches_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

replay-branches-check: $(BUILD)/elisa-debugger-replay-branches-check
	"$(BUILD)/elisa-debugger-replay-branches-check"

$(BUILD)/elisa-debugger-replay-provenance-check: tests/replay_provenance_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

replay-provenance-check: $(BUILD)/elisa-debugger-replay-provenance-check
	"$(BUILD)/elisa-debugger-replay-provenance-check"

$(BUILD)/elisa-debugger-replay-seek-atomicity-check: tests/replay_seek_atomicity_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

replay-seek-atomicity-check: $(BUILD)/elisa-debugger-replay-seek-atomicity-check
	"$(BUILD)/elisa-debugger-replay-seek-atomicity-check"

$(BUILD)/elisa-debugger-state-integrity-check: tests/state_integrity_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

state-integrity-check: $(BUILD)/elisa-debugger-state-integrity-check
	"$(BUILD)/elisa-debugger-state-integrity-check"

request-whitespace-check: $(BUILD)/elisa-debugger-request-whitespace-check
	"$(BUILD)/elisa-debugger-request-whitespace-check"

$(BUILD)/elisa-debugger-request-operands-check: tests/request_operands_check.elisa $(ELISA_BUILD_INPUTS)
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

$(BUILD)/elisa-debugger-dap-payload-check: tests/dap_payload_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-dap-events-check: tests/dap_events_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-events-check: $(BUILD)/elisa-debugger-dap-events-check
	"$(BUILD)/elisa-debugger-dap-events-check"

$(BUILD)/elisa-debugger-dap-continue-partial-check: tests/dap_continue_partial_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-continue-partial-check: $(BUILD)/elisa-debugger-dap-continue-partial-check
	"$(BUILD)/elisa-debugger-dap-continue-partial-check"

dap-command-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	sh tests/dap_command_collision_check.sh "$(BUILD)/elisa-debugger-dap-server" "$(BUILD)/edir-fixture.edir"

dap-frame-length-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	sh tests/dap_frame_lengths_check.sh "$(BUILD)/elisa-debugger-dap-server" "$(BUILD)/edir-fixture.edir"

# Exercise frame projection, paging, legacy names, locals, and payload parsing.
$(DAP_STACK_FRAMES_CHECK): tests/dap_stack_frames_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-stack-frames-check: $(DAP_STACK_FRAMES_CHECK)
	"$(DAP_STACK_FRAMES_CHECK)"

# Native snapshot pages are root-to-current; verify the adapter projection's
# DAP ordering, source lookup, stable handles, and corruption guards.
.PHONY: dap-native-frames-check dap-native-variables-check dap-native-variables-json-check
$(BUILD)/elisa-debugger-dap-native-frames-check: tests/dap_native_frames_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-native-frames-check: $(BUILD)/elisa-debugger-dap-native-frames-check
	"$(BUILD)/elisa-debugger-dap-native-frames-check"

# Exercise typed native locals projection, metadata resolution, and paging.
$(BUILD)/elisa-debugger-dap-native-variables-check: tests/dap_native_variables_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-native-variables-check: $(BUILD)/elisa-debugger-dap-native-variables-check
	"$(BUILD)/elisa-debugger-dap-native-variables-check"

# Ensure native locals JSON serialization preserves escaping and rejects
# corrupted pages before producing a standard DAP response body.
$(BUILD)/elisa-debugger-dap-native-variables-json-check: tests/dap_native_variables_json_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-native-variables-json-check: $(BUILD)/elisa-debugger-dap-native-variables-json-check
	"$(BUILD)/elisa-debugger-dap-native-variables-json-check"

# Exercise the real DAP transport first at the root frame and then inside the
# EDIR fixture's call, where stackTrace must not mislabel the callee as main.
dap-stack-frame-check: edir-file-loader-check $(BUILD)/elisa-debugger-dap-server
	dap_stack_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"stepIn"}' '{"seq":9,"type":"request","command":"stepIn"}' '{"seq":10,"type":"request","command":"stackTrace","arguments":{"threadId":1}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_stack_output=$$(printf %s "$$dap_stack_input" | "$(BUILD)/elisa-debugger-dap-server"); test "$$(printf %s "$$dap_stack_output" | grep -o '\"name\":\"main\"' | wc -l | tr -d ' ')" -eq 1; test "$$(printf %s "$$dap_stack_output" | grep -o '\"name\":\"callee\"' | wc -l | tr -d ' ')" -eq 1

dap-payload-check: $(BUILD)/elisa-debugger-dap-payload-check
	"$(BUILD)/elisa-debugger-dap-payload-check"

.PHONY: dap-column-breakpoints-check
$(BUILD)/elisa-debugger-dap-column-fixture-writer: tests/dap_column_fixture_writer.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-dap-column-breakpoints-check: tests/dap_column_breakpoints_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

dap-column-breakpoints-check: $(BUILD)/elisa-debugger-dap-server $(BUILD)/elisa-debugger-dap-column-fixture-writer $(BUILD)/elisa-debugger-dap-column-breakpoints-check
	sh tests/dap_column_breakpoints_check.sh "$(BUILD)/elisa-debugger-dap-column-fixture-writer" "$(BUILD)/elisa-debugger-dap-column-breakpoints-check" "$(BUILD)/elisa-debugger-dap-server"

$(BUILD)/elisa-debugger-edir-fixture-writer: tests/edir_fixture_writer.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-edir-file-loader-check: tests/edir_file_loader_check.elisa $(ELISA_BUILD_INPUTS)
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

$(COMPILER_EDIR_INTEGRATION_CHECK): tests/compiler_edir_integration_check.elisa $(ELISA_BUILD_INPUTS)
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
	compiler_dap_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize","arguments":{"supportsVariableType":true}}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(COMPILER_EDIR_ARTIFACT)"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stepIn"}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_DAP_FRAME_ID)}}' '{"seq":9,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_DAP_LOCAL_REFERENCE)}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); compiler_dap_output=$$(printf %s "$$compiler_dap_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$compiler_dap_output" | grep -F '"name":"local0","value":"40","type":"i64"'
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit exe -O0 -o "$(COMPILER_NATIVE_ARTIFACT)" "$(COMPILER_EDIR_FIXTURE)"
	native_status=0; "$(COMPILER_NATIVE_ARTIFACT)" || native_status=$$?; test "$$native_status" -eq "$(COMPILER_EDIR_EXPECTED_EXIT)"


$(COMPILER_EDIR_CORE_IR_CHECK): tests/compiler_edir_core_ir_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

# This direct-return fixture is deliberately small enough to qualify for the
# compiler's shared typed CoreIR path. Check its source spans and result in the
# managed VM, assert the native LLVM marker at O0, then run native O0 and O2 so
# the current compiler optimization pipeline is exercised on the same source.
compiler-edir-core-ir-check: $(COMPILER_EDIR_CORE_IR_CHECK)
	mkdir -p $(BUILD)
	ELISA_EDIR_SOURCE_ROOT="$(CURDIR)" ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit edir -O0 -o "$(COMPILER_EDIR_CORE_IR_ARTIFACT)" "$(COMPILER_EDIR_CORE_IR_FIXTURE)"
	"$(COMPILER_EDIR_CORE_IR_CHECK)"
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit llvm -O0 -o "$(COMPILER_EDIR_CORE_IR_LLVM)" "$(COMPILER_EDIR_CORE_IR_FIXTURE)"
	grep -F "$(COMPILER_EDIR_CORE_IR_LLVM_MARKER)" "$(COMPILER_EDIR_CORE_IR_LLVM)" >/dev/null
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit exe -O0 -o "$(COMPILER_EDIR_CORE_IR_NATIVE_O0)" "$(COMPILER_EDIR_CORE_IR_FIXTURE)"
	native_o0_status=0; "$(COMPILER_EDIR_CORE_IR_NATIVE_O0)" || native_o0_status=$$?; test "$$native_o0_status" -eq "$(COMPILER_EDIR_CORE_IR_EXPECTED_EXIT)"
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit exe -O2 -o "$(COMPILER_EDIR_CORE_IR_NATIVE_O2)" "$(COMPILER_EDIR_CORE_IR_FIXTURE)"
	native_o2_status=0; "$(COMPILER_EDIR_CORE_IR_NATIVE_O2)" || native_o2_status=$$?; test "$$native_o2_status" -eq "$(COMPILER_EDIR_CORE_IR_EXPECTED_EXIT)"

$(COMPILER_EDIR_LOOP_INTEGRATION_CHECK): tests/compiler_edir_counted_loop_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

# Compile the same counted loop to EDIR and native code, then exercise the VM and
# DAP reverse stepping against the compiler-emitted source spans and branches.
compiler-edir-loop-check: $(COMPILER_EDIR_LOOP_INTEGRATION_CHECK) $(BUILD)/elisa-debugger-dap-server
	mkdir -p $(BUILD)
	ELISA_EDIR_SOURCE_ROOT="$(CURDIR)" ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit edir -O0 -o "$(COMPILER_EDIR_LOOP_ARTIFACT)" "$(COMPILER_EDIR_LOOP_FIXTURE)"
	"$(COMPILER_EDIR_LOOP_INTEGRATION_CHECK)"
	loop_dap_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize","arguments":{"supportsVariableType":true}}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(COMPILER_EDIR_LOOP_ARTIFACT)","sourcePathRoot":"$(CURDIR)"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"$(CURDIR)/$(COMPILER_EDIR_LOOP_FIXTURE)"},"breakpoints":[{"line":$(COMPILER_EDIR_LOOP_BREAKPOINT_LINE),"condition":"local1 == 0"}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_LOOP_DAP_INITIAL_FRAME_ID)}}' '{"seq":6,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_LOOP_DAP_INITIAL_LOCALS_REFERENCE)}}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"stepIn"}' '{"seq":9,"type":"request","command":"stepIn"}' '{"seq":10,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_LOOP_DAP_STEPPED_FRAME_ID)}}' '{"seq":11,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_LOOP_DAP_STEPPED_LOCALS_REFERENCE)}}' '{"seq":12,"type":"request","command":"stepBack"}' '{"seq":13,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' '{"seq":14,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_LOOP_DAP_REVERSED_FRAME_ID)}}' '{"seq":15,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_LOOP_DAP_REVERSED_LOCALS_REFERENCE)}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); loop_dap_output=$$(printf %s "$$loop_dap_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$loop_dap_output" | grep -F '"reason":"breakpoint"'; echo "$$loop_dap_output" | grep -F '"name":"local0","value":"0","type":"i64"'; echo "$$loop_dap_output" | grep -F '"name":"local1","value":"0","type":"i64"'; echo "$$loop_dap_output" | grep -F '"name":"local1","value":"2","type":"i64"'; echo "$$loop_dap_output" | grep -F '"line":4'; test "$$(printf '%s\n' "$$loop_dap_output" | grep -F -c '"name":"local1","value":"2","type":"i64"')" -ge 2
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit exe -O0 -o "$(COMPILER_EDIR_LOOP_NATIVE_ARTIFACT)" "$(COMPILER_EDIR_LOOP_FIXTURE)"
	loop_native_status=0; "$(COMPILER_EDIR_LOOP_NATIVE_ARTIFACT)" || loop_native_status=$$?; test "$$loop_native_status" -eq "$(COMPILER_EDIR_LOOP_EXPECTED_EXIT)"

$(COMPILER_EDIR_CALLS_CHECK): tests/compiler_edir_calls_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

# Compile the recursive call fixture through the latest compiler's schema-3
# EDIR function-table path, execute it in the managed VM, and compare the
# optimized native backend result. Keep the old target as an alias so existing
# local scripts continue to run while they migrate to the positive gate.
compiler-edir-calls-check: $(COMPILER_EDIR_CALLS_CHECK)
	mkdir -p $(BUILD)
	ELISA_EDIR_SOURCE_ROOT="$(CURDIR)" ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit edir -O$(COMPILER_EDIR_CALLS_EDIR_OPTIMIZATION_LEVEL) -o "$(COMPILER_EDIR_CALLS_ARTIFACT)" "$(COMPILER_EDIR_CALLS_FIXTURE)"
	"$(COMPILER_EDIR_CALLS_CHECK)"
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_EDIR_ALLOW_STALE_STAGE1)" "$(ELISA_EDIR_COMPILER)" -emit exe -O$(COMPILER_EDIR_CALLS_NATIVE_OPTIMIZATION_LEVEL) -o "$(COMPILER_EDIR_CALLS_NATIVE_ARTIFACT)" "$(COMPILER_EDIR_CALLS_FIXTURE)"
	calls_native_status=$(COMPILER_EDIR_CALLS_NATIVE_SUCCESS_STATUS); "$(COMPILER_EDIR_CALLS_NATIVE_ARTIFACT)" || calls_native_status=$$?; test "$$calls_native_status" -eq "$(COMPILER_EDIR_CALLS_EXPECTED_EXIT)"

compiler-edir-calls-unsupported-check: compiler-edir-calls-check

$(BUILD)/elisa-debugger-timeline-capability-check: tests/timeline_capability_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

timeline-capability-check: $(BUILD)/elisa-debugger-timeline-capability-check
	"$(BUILD)/elisa-debugger-timeline-capability-check"

ffi-check: $(BUILD)/elisa-debugger-ffi-probe
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

$(BUILD)/elisa-debugger-process-spawn-check: tests/process_spawn_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

process-spawn-check: $(BUILD)/elisa-debugger-process-spawn-check
	"$(BUILD)/elisa-debugger-process-spawn-check" $(PROCESS_SPAWN_CHECK_PARENT_MODE) $(PROCESS_SPAWN_CHECK_RESERVED_FIRST) $(PROCESS_SPAWN_CHECK_RESERVED_SECOND)

$(BUILD)/elisa-debugger-build-runner-check: tests/build_runner_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

build-runner-check: $(BUILD)/elisa-debugger-build-runner-check
	"$(BUILD)/elisa-debugger-build-runner-check"

$(BUILD)/elisa-debugger: $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" src/main.elisa

$(BUILD)/elisa-debugger-server: src/protocol/server.elisa src/protocol/framing.elisa src/protocol/request.elisa src/protocol/dispatcher.elisa src/protocol/managed_service.elisa src/core/errors.elisa src/core/identity.elisa src/core/capabilities.elisa src/core/cancellation.elisa src/core/session.elisa src/core/events.elisa src/engine/coordinator.elisa src/engine/managed.elisa src/engine/default_image.elisa src/replay/engine.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-dap-server: src/protocol/dap_server.elisa src/protocol/dispatcher.elisa src/core/cancellation.elisa src/engine/coordinator.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-cli: src/cli/entrypoint.elisa src/protocol/dispatcher.elisa src/core/cancellation.elisa src/engine/coordinator.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-core-check: tests/module_core_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-data-check: tests/module_data_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-effect-oracle-check: tests/effect_oracle_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-protocol-check: tests/module_protocol_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-codec-check: tests/trace_codec_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-recording-check: tests/trace_recording_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-module-trace-bundle-check: tests/trace_bundle_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-codec-check: $(BUILD)/elisa-debugger-module-trace-codec-check
	"$(BUILD)/elisa-debugger-module-trace-codec-check"

effect-oracle-check: $(BUILD)/elisa-debugger-effect-oracle-check
	"$(BUILD)/elisa-debugger-effect-oracle-check"

trace-recording-check: $(BUILD)/elisa-debugger-module-trace-recording-check
	"$(BUILD)/elisa-debugger-module-trace-recording-check"

trace-bundle-check: $(BUILD)/elisa-debugger-module-trace-bundle-check
	"$(BUILD)/elisa-debugger-module-trace-bundle-check"

$(BUILD)/elisa-debugger-edir-call-check: tests/edir_call_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-edir-codec-check: tests/edir_codec_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-breakpoint-resolver-check: tests/breakpoint_resolver_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

breakpoint-resolver-check: $(BUILD)/elisa-debugger-breakpoint-resolver-check
	"$(BUILD)/elisa-debugger-breakpoint-resolver-check"

$(BUILD)/elisa-debugger-path-policy-check: tests/path_policy_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

path-policy-check: $(BUILD)/elisa-debugger-path-policy-check
	"$(BUILD)/elisa-debugger-path-policy-check"

edir-codec-check: $(BUILD)/elisa-debugger-edir-codec-check
	"$(BUILD)/elisa-debugger-edir-codec-check"

$(BUILD)/elisa-debugger-session-check: tests/session_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-ffi-probe: tests/ffi_probe.elisa $(ELISA_COMPILER_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-inspection-check: tests/managed_inspection_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(MANAGED_ALLOCATIONS_CHECK): tests/managed_allocations_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

managed-allocations-check: $(MANAGED_ALLOCATIONS_CHECK)
	"$(MANAGED_ALLOCATIONS_CHECK)"

$(BUILD)/elisa-debugger-managed-service-check: tests/managed_service_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-trace-service-check: tests/managed_trace_service_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-managed-memory-write-history-check: tests/managed_memory_write_history_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

managed-memory-write-history-check: $(BUILD)/elisa-debugger-managed-memory-write-history-check
	"$(BUILD)/elisa-debugger-managed-memory-write-history-check"

$(BUILD)/elisa-debugger-protocol-events-check: tests/protocol_events_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-protocol-client-ordering-check: tests/protocol_client_ordering_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

protocol-client-ordering-check: $(BUILD)/elisa-debugger-protocol-client-ordering-check
	"$(BUILD)/elisa-debugger-protocol-client-ordering-check"

$(BUILD)/elisa-debugger-protocol-encoding-check: tests/protocol_encoding_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-protocol-framing-check: tests/protocol_framing_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-session-ownership-check: tests/session_ownership_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

session-ownership-check: $(BUILD)/elisa-debugger-session-ownership-check
	"$(BUILD)/elisa-debugger-session-ownership-check"

protocol-framing-check: $(BUILD)/elisa-debugger-protocol-framing-check
	"$(BUILD)/elisa-debugger-protocol-framing-check"

$(BUILD)/elisa-debugger-server-buffer-check: tests/server_buffer_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

server-buffer-check: $(BUILD)/elisa-debugger-server-buffer-check
	"$(BUILD)/elisa-debugger-server-buffer-check"

server-flush-check: $(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server
	sh tests/server_flush_check.sh "$(BUILD)/elisa-debugger-server" "$(BUILD)/elisa-debugger-dap-server"

$(BUILD)/elisa-debugger-trace-storage-decode-check: tests/trace_storage_decode_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-storage-decode-check: $(BUILD)/elisa-debugger-trace-storage-decode-check
	"$(BUILD)/elisa-debugger-trace-storage-decode-check"

$(BUILD)/elisa-debugger-trace-file-check: tests/trace_file_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-file-check: $(BUILD)/elisa-debugger-trace-file-check
	"$(BUILD)/elisa-debugger-trace-file-check"

$(BUILD)/elisa-debugger-trace-reader-encoded-check: tests/trace_reader_encoded_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-reader-encoded-check: $(BUILD)/elisa-debugger-trace-reader-encoded-check
	"$(BUILD)/elisa-debugger-trace-reader-encoded-check"

$(BUILD)/elisa-debugger-trace-checkpoint-validation-check: tests/trace_checkpoint_validation_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-checkpoint-validation-check: $(BUILD)/elisa-debugger-trace-checkpoint-validation-check
	"$(BUILD)/elisa-debugger-trace-checkpoint-validation-check"

$(BUILD)/elisa-debugger-remote-authentication-check: tests/remote_authentication_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

remote-authentication-check: $(BUILD)/elisa-debugger-remote-authentication-check
	"$(BUILD)/elisa-debugger-remote-authentication-check"

$(BUILD)/elisa-debugger-remote-authorization-check: tests/remote_authorization_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

remote-authorization-check: $(BUILD)/elisa-debugger-remote-authorization-check
	"$(BUILD)/elisa-debugger-remote-authorization-check"

$(BUILD)/elisa-debugger-remote-artifacts-check: tests/remote_artifacts_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

remote-artifacts-check: $(BUILD)/elisa-debugger-remote-artifacts-check
	"$(BUILD)/elisa-debugger-remote-artifacts-check"

$(BUILD)/elisa-debugger-native-elf-check: tests/native_elf_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-elf-check: $(BUILD)/elisa-debugger-native-elf-check
	"$(BUILD)/elisa-debugger-native-elf-check"

$(BUILD)/elisa-debugger-native-macho-check: tests/native_macho_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macho-check: $(BUILD)/elisa-debugger-native-macho-check
	"$(BUILD)/elisa-debugger-native-macho-check"

$(BUILD)/elisa-debugger-native-dwarf-line-check: tests/native_dwarf_line_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-dwarf-line-check: $(BUILD)/elisa-debugger-native-dwarf-line-check
	"$(BUILD)/elisa-debugger-native-dwarf-line-check"

$(ELF_DWARF_LINE_FIXTURE): $(ELF_DWARF_LINE_FIXTURE_SOURCE)
	mkdir -p $(BUILD)
	$(ELF_DWARF_LINE_CC) $(ELF_DWARF_LINE_TARGET_FLAGS) -gdwarf-4 -O0 -nostdlib -static -Wl,-e,main -o "$@" "$<"

$(BUILD)/elisa-debugger-native-elf-dwarf-line-check: tests/native_elf_dwarf_line_check.elisa $(ELF_DWARF_LINE_FIXTURE) $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-elf-dwarf-line-check: $(BUILD)/elisa-debugger-native-elf-dwarf-line-check
	"$(BUILD)/elisa-debugger-native-elf-dwarf-line-check"

$(BUILD)/elisa-debugger-native-macho-dwarf-line-check: tests/native_macho_dwarf_line_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macho-dwarf-line-check: $(BUILD)/elisa-debugger-native-macho-dwarf-line-check
	"$(BUILD)/elisa-debugger-native-macho-dwarf-line-check"

$(BUILD)/elisa-debugger-native-artifact-check: tests/native_artifact_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-artifact-check: $(BUILD)/elisa-debugger-native-artifact-check
	"$(BUILD)/elisa-debugger-native-artifact-check"

$(BUILD)/elisa-debugger-native-jetsam-check: tests/native_jetsam_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-jetsam-check: $(BUILD)/elisa-debugger-native-jetsam-check
	"$(BUILD)/elisa-debugger-native-jetsam-check"

$(BUILD)/elisa-debugger-jetsam: src/native/jetsam_cli.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-jetsam-tool: $(BUILD)/elisa-debugger-jetsam

$(BUILD)/elisa-debugger-native-macos-resources-check: tests/native_macos_resources_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macos-resources-check: $(BUILD)/elisa-debugger-native-macos-resources-check
	"$(BUILD)/elisa-debugger-native-macos-resources-check"

$(BUILD)/elisa-debugger-procinfo: src/native/macos_resources_cli.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macos-resources-tool: $(BUILD)/elisa-debugger-procinfo

$(BUILD)/elisa-debugger-native-macos-memory-check: tests/native_macos_memory_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macos-memory-check: $(BUILD)/elisa-debugger-native-macos-memory-check
	"$(BUILD)/elisa-debugger-native-macos-memory-check"

$(BUILD)/elisa-debugger-native-macos-attach-check: tests/native_macos_attach_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macos-attach-check: $(BUILD)/elisa-debugger-native-macos-attach-check
	sh tests/native_macos_attach_check.sh "$(BUILD)/elisa-debugger-native-macos-attach-check"

$(BUILD)/elisa-debugger-memread: src/native/macos_memory_cli.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-macos-memory-tool: $(BUILD)/elisa-debugger-memread

$(BUILD)/elisa-debugger-native-symbols-identity-check: tests/native_symbols_identity_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-symbols-identity-check: $(BUILD)/elisa-debugger-native-symbols-identity-check
	"$(BUILD)/elisa-debugger-native-symbols-identity-check"

$(BUILD)/elisa-debugger-native-symbol-loader-check: tests/native_symbol_loader_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-symbol-loader-check: $(BUILD)/elisa-debugger-native-symbol-loader-check
	"$(BUILD)/elisa-debugger-native-symbol-loader-check"

$(BUILD)/elisa-debugger-native-controller-check: tests/native_controller_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-controller-check: $(BUILD)/elisa-debugger-native-controller-check
	"$(BUILD)/elisa-debugger-native-controller-check"

$(BUILD)/elisa-debugger-native-agent-controller-check: tests/native_agent_controller_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-agent-controller-check: $(BUILD)/elisa-debugger-native-agent-controller-check
	"$(BUILD)/elisa-debugger-native-agent-controller-check"

$(BUILD)/elisa-debugger-native-local-ipc-check: tests/native_local_ipc_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-local-ipc-check: $(BUILD)/elisa-debugger-native-local-ipc-check
	"$(BUILD)/elisa-debugger-native-local-ipc-check"

$(BUILD)/elisa-debugger-native-local-agent-transport-check: tests/native_local_agent_transport_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-local-agent-transport-check: $(BUILD)/elisa-debugger-native-local-agent-transport-check
	"$(BUILD)/elisa-debugger-native-local-agent-transport-check" --local-agent-parent reserved-first reserved-second

$(BUILD)/elisa-debugger-agent-wire-check: tests/agent_wire_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-wire-check: $(BUILD)/elisa-debugger-agent-wire-check
	"$(BUILD)/elisa-debugger-agent-wire-check"

$(BUILD)/elisa-debugger-agent-wire-stream-check: tests/agent_wire_stream_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-wire-stream-check: $(BUILD)/elisa-debugger-agent-wire-stream-check
	"$(BUILD)/elisa-debugger-agent-wire-stream-check"

$(BUILD)/elisa-debugger-agent-handshake-check: tests/agent_handshake_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-handshake-check: $(BUILD)/elisa-debugger-agent-handshake-check
	"$(BUILD)/elisa-debugger-agent-handshake-check"

$(BUILD)/elisa-debugger-agent-control-check: tests/agent_control_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-control-check: $(BUILD)/elisa-debugger-agent-control-check
	"$(BUILD)/elisa-debugger-agent-control-check"

$(BUILD)/elisa-debugger-agent-control-stream-check: tests/agent_control_stream_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-control-stream-check: $(BUILD)/elisa-debugger-agent-control-stream-check
	"$(BUILD)/elisa-debugger-agent-control-stream-check"

$(BUILD)/elisa-debugger-agent-thread-rendezvous-check: tests/agent_thread_rendezvous_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-thread-rendezvous-check: $(BUILD)/elisa-debugger-agent-thread-rendezvous-check
	"$(BUILD)/elisa-debugger-agent-thread-rendezvous-check"

$(BUILD)/elisa-debugger-agent-session-transport-check: tests/agent_session_transport_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-session-transport-check: $(BUILD)/elisa-debugger-agent-session-transport-check
	"$(BUILD)/elisa-debugger-agent-session-transport-check" --agent-session-parent reserved-first reserved-second

$(BUILD)/elisa-debugger-agent-async-session-transport-check: tests/agent_async_session_transport_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-async-session-transport-check: $(BUILD)/elisa-debugger-agent-async-session-transport-check
	"$(BUILD)/elisa-debugger-agent-async-session-transport-check" --agent-session-parent reserved-first reserved-second

$(BUILD)/elisa-debugger-agent-shadow-frames-check: tests/agent_shadow_frames_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-shadow-frames-check: $(BUILD)/elisa-debugger-agent-shadow-frames-check
	"$(BUILD)/elisa-debugger-agent-shadow-frames-check"

$(BUILD)/elisa-debugger-agent-inspection-rendezvous-check: tests/agent_inspection_rendezvous_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-inspection-rendezvous-check: $(BUILD)/elisa-debugger-agent-inspection-rendezvous-check
	"$(BUILD)/elisa-debugger-agent-inspection-rendezvous-check"

$(BUILD)/elisa-debugger-agent-snapshot-wire-check: tests/agent_snapshot_wire_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-snapshot-wire-check: $(BUILD)/elisa-debugger-agent-snapshot-wire-check
	"$(BUILD)/elisa-debugger-agent-snapshot-wire-check"

$(BUILD)/elisa-debugger-agent-value-codec-check: tests/agent_value_codec_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

agent-value-codec-check: $(BUILD)/elisa-debugger-agent-value-codec-check
	"$(BUILD)/elisa-debugger-agent-value-codec-check"

$(BUILD)/elisa-debugger-native-breakpoint-lifecycle-check: tests/native_breakpoint_lifecycle_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

native-breakpoint-lifecycle-check: $(BUILD)/elisa-debugger-native-breakpoint-lifecycle-check
	"$(BUILD)/elisa-debugger-native-breakpoint-lifecycle-check"

protocol-encoding-check: $(BUILD)/elisa-debugger-protocol-encoding-check
	"$(BUILD)/elisa-debugger-protocol-encoding-check"

$(BUILD)/elisa-debugger-checkpoint-state-check: tests/checkpoint_state_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

checkpoint-state-check: $(BUILD)/elisa-debugger-checkpoint-state-check
	"$(BUILD)/elisa-debugger-checkpoint-state-check"

$(BUILD)/elisa-debugger-full-checkpoint-codec-check: tests/full_checkpoint_codec_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

full-checkpoint-codec-check: $(BUILD)/elisa-debugger-full-checkpoint-codec-check
	"$(BUILD)/elisa-debugger-full-checkpoint-codec-check"

$(BUILD)/elisa-debugger-trace-manifest-status-check: tests/trace_manifest_status_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

trace-manifest-status-check: $(BUILD)/elisa-debugger-trace-manifest-status-check
	"$(BUILD)/elisa-debugger-trace-manifest-status-check"

$(BUILD)/elisa-debugger-adapter-recording-bounds-check: tests/adapter_recording_bounds_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

adapter-recording-bounds-check: $(BUILD)/elisa-debugger-adapter-recording-bounds-check
	"$(BUILD)/elisa-debugger-adapter-recording-bounds-check"

$(BUILD)/elisa-debugger-runtime-status-check: tests/runtime_status_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

runtime-status-check: $(BUILD)/elisa-debugger-runtime-status-check
	"$(BUILD)/elisa-debugger-runtime-status-check"

$(BUILD)/elisa-debugger-concurrency-scheduler-check: tests/concurrency_schedule_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

concurrency-scheduler-check: $(BUILD)/elisa-debugger-concurrency-scheduler-check
	"$(BUILD)/elisa-debugger-concurrency-scheduler-check"

$(CONCURRENCY_RACES_CHECK): tests/concurrency_races_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

concurrency-races-check: $(CONCURRENCY_RACES_CHECK)
	"$(CONCURRENCY_RACES_CHECK)"

$(EXPRESSION_PARSER_CHECK): tests/expression_parser_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

expression-parser-check: $(EXPRESSION_PARSER_CHECK)
	"$(EXPRESSION_PARSER_CHECK)"

$(BUILD)/elisa-debugger-source-store-check: tests/source_store_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-metadata-names-check: tests/metadata_names_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

metadata-names-check: $(BUILD)/elisa-debugger-metadata-names-check
	"$(BUILD)/elisa-debugger-metadata-names-check"

$(BUILD)/elisa-debugger-type-metadata-check: tests/type_metadata_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

type-metadata-check: $(BUILD)/elisa-debugger-type-metadata-check
	"$(BUILD)/elisa-debugger-type-metadata-check"

$(BUILD)/elisa-debugger-request-whitespace-check: tests/request_whitespace_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-cli-commands-check: tests/cli_commands_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-value-store-check: tests/value_store_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-historical-values-check: tests/historical_values_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-query-engine-check: tests/query_engine_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-query-evaluator-check: tests/query_evaluator_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-breakpoint-manager-check: tests/breakpoint_manager_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-advanced-analysis-check: tests/advanced_analysis_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-integration-contract-check: tests/integration_contract_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-integration-surface-check: tests/integration_surface_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

integration-surface-check: $(BUILD)/elisa-debugger-integration-surface-check
	"$(BUILD)/elisa-debugger-integration-surface-check"

$(BUILD)/elisa-debugger-trace-retention-check: tests/trace_retention_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-coordinator-seek-check: tests/coordinator_seek_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

$(BUILD)/elisa-debugger-capabilities-check: tests/capabilities_check.elisa $(ELISA_BUILD_INPUTS)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

check: $(BUILD)/elisa-debugger
	"$(BUILD)/elisa-debugger"

smoke: check server server-version-check dap-server cli cli-flush-check ffi-check edir-file-loader-check managed-source-path-check server-flush-check dap-command-check dap-frame-length-check
	dap_windows_case_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir","sourcePathRoot":"C:\\Workspace"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"c:\\workspace\\main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace","arguments":{"threadId":1}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_windows_case_paths=$$(printf %s "$$dap_windows_case_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_windows_case_paths" | grep -F '"command":"setBreakpoints","success":true'; echo "$$dap_windows_case_paths" | grep -F '"source":{"name":"main.elisa","path":"C:/Workspace/main.elisa"}'; echo "$$dap_windows_case_paths" | grep -F '"reason":"breakpoint"'
	dap_unc_path_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir","sourcePathRoot":"\\\\server\\share"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"\\\\SERVER\\SHARE\\main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace","arguments":{"threadId":1}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_unc_paths=$$(printf %s "$$dap_unc_path_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_unc_paths" | grep -F '"command":"setBreakpoints","success":true'; echo "$$dap_unc_paths" | grep -F '"source":{"name":"main.elisa","path":"//server/share/main.elisa"}'; echo "$$dap_unc_paths" | grep -F '"reason":"breakpoint"'
	printf '655360 ' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf '21 {' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf '$(IDLESS_LAUNCH_PAYLOAD_LENGTH) {"method":"launch"}\n' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 655360\r\n\r\n' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf '21 {"method":"discover"}\n' | "$(BUILD)/elisa-debugger-server" | grep -F '"protocolMajor":1' | grep -F '"productVersion":"0.1.0"' | grep -F '"sourceBreakpoints":true' | grep -F '"reverseExecution":true' | grep -F '"typedValues":true' | grep -F '"historicalQueries":false' | grep -F '"memoryRead":true' | grep -F '"checkpoints":true' | grep -F '"branches":true' | grep -F '"traceVerification":true' | grep -F '"traceExport":false' | grep -F '"installationHealthy":true'
	server_timeline_input=$$(for payload in '$(SERVER_INITIALIZE_PAYLOAD)' '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"reverseStep","id":4}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_timeline=$$(printf '%s\n' "$$server_timeline_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_timeline" | grep -F '"id":"3","ok":true'; echo "$$server_timeline" | grep -F '"id":"4","ok":true'; printf '%s\n' "$$server_timeline" | while IFS=' ' read -r declared payload; do test "$$declared" -eq "$$(printf %s "$$payload" | wc -c | tr -d ' ')"; done
	server_launch_state_input=$$(for payload in '$(SERVER_INITIALIZE_PAYLOAD)' '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"launch","id":4,"expectedStopGeneration":$(SERVER_TEST_STALE_GENERATION),"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"launch","id":5,"expectedStopGeneration":$(SERVER_TEST_CURRENT_GENERATION),"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"stack","id":6}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_launch_state=$$(printf '%s\n' "$$server_launch_state_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_launch_state" | grep -F '"id":"4","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_launch_state" | grep -F '"id":"5","ok":false' | grep -F '"code":"INVALID_STATE"'; echo "$$server_launch_state" | grep -F '"id":"6","ok":true' | grep -F '"instruction":"$(SERVER_TEST_FIRST_STEP_INSTRUCTION)"' | grep -F '"accumulator":"$(SERVER_TEST_FIRST_STEP_ACCUMULATOR)"'
	server_inspection_input=$$(for payload in '$(SERVER_INITIALIZE_PAYLOAD)' '{"method":"launch","id":1,"arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"method":"pause","id":2}' '{"method":"step","id":3}' '{"method":"step","id":4}' '{"method":"step","id":5}' '{"method":"step","id":6}' '{"method":"stack","id":7}' '{"method":"scopes","id":8}' '{"method":"variables","id":9,"arguments":{"variablesReference":"5"},"pageSize":$(SERVER_TEST_PAGE_SIZE),"pageStart":0}' '{"method":"variables","id":10,"arguments":{"variablesReference":"5"},"pageSize":$(SERVER_TEST_PAGE_SIZE),"pageStart":"1"}' '{"method":"variables","id":11,"arguments":{"variablesReference":"4"}}' '{"method":"threads","id":12}' '{"method":"memory","id":13,"arguments":{"address":"0","length":1}}' '{"method":"trace.verify","id":14,"expectedStopGeneration":"$(SERVER_TEST_STALE_GENERATION)"}' '{"method":"trace.verify","id":15}' '{"method":"checkpoint","id":16}' '{"method":"branch","id":17}' '{"method":"reverseStep","id":18}' '{"method":"trace.verify","id":19}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf '%s %s\n' "$$frame_length" "$$payload"; done); server_inspection=$$(printf '%s\n' "$$server_inspection_input" | "$(BUILD)/elisa-debugger-server"); echo "$$server_inspection" | grep -F '"id":"7","ok":true' | grep -F '"frame":{"name":"frame"'; echo "$$server_inspection" | grep -F '"id":"8","ok":true' | grep -F '"variablesReference"'; echo "$$server_inspection" | grep -F '"id":"9","ok":true' | grep -F '"name":"local0"' | grep -F '"value":"17"' | grep -F '"complete":false' | grep -F '"next":"1"'; echo "$$server_inspection" | grep -F '"id":"10","ok":true' | grep -F '"name":"local1"' | grep -F '"value":"29"' | grep -F '"complete":true' | grep -F '"next":null'; echo "$$server_inspection" | grep -F '"id":"11","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_inspection" | grep -F '"id":"12","ok":true' | grep -F '"threads":[{"id":"1","name":"main"}]'; echo "$$server_inspection" | grep -F '"id":"13","ok":false' | grep -F '"code":"UNAVAILABLE"'; echo "$$server_inspection" | grep -F '"id":"14","ok":false' | grep -F '"code":"STALE_GENERATION"'; echo "$$server_inspection" | grep -F '"id":"15","ok":true' | grep -F '"verification":{"state":"exact"'; echo "$$server_inspection" | grep -F '"id":"16","ok":true' | grep -F '"checkpoint":{"available":true'; echo "$$server_inspection" | grep -F '"id":"17","ok":true' | grep -F '"branch":{"id":"1"}'; echo "$$server_inspection" | grep -F '"id":"18","ok":true'; echo "$$server_inspection" | grep -F '"id":"19","ok":true' | grep -F '"verification":{"state":"partial"}'
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"supportsStepBack":true'
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"supportsLogPoints":true' | grep -F '"supportsConditionalBreakpoints":true' | grep -F '"supportsEvaluateForHovers":true' | grep -F '"supportsDataBreakpoints":false'
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
	dap_fixture_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"configurationDone"}' '{"seq":4,"type":"request","command":"pause"}' '{"seq":5,"type":"request","command":"stackTrace","arguments":{"threadId":1}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_fixture=$$(printf %s "$$dap_fixture_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_fixture" | grep -F '"command":"launch","success":true'; echo "$$dap_fixture" | grep -F '"stackFrames":[{"id":$(DAP_FIRST_STOP_FRAME_ID),"name":"main","line":41,"column":$(DAP_EXPECTED_MAPPED_COLUMN)'
	dap_thread_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"threads"}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_thread_listing=$$(printf %s "$$dap_thread_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_thread_listing" | grep -F '"command":"threads","success":true,"body":{"threads":[{"id":1,"name":"main"}]}'
	initialize_payload='{"seq":1,"type":"request","command":"initialize","arguments":{"linesStartAt1":false,"columnsStartAt1":false}}'; initialize_length=$$(printf %s "$$initialize_payload" | wc -c | tr -d ' '); launch_payload='{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}'; launch_length=$$(printf %s "$$launch_payload" | wc -c | tr -d ' '); dap_zero_based=$$(printf 'Content-Length: %s\r\n\r\n%sContent-Length: %s\r\n\r\n%sContent-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 76\r\n\r\n{"seq":4,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' "$$initialize_length" "$$initialize_payload" "$$launch_length" "$$launch_payload" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_zero_based" | grep -F '"stackFrames":[{"id":$(DAP_FIRST_STOP_FRAME_ID),"name":"main","line":$(DAP_ZERO_BASED_MAPPED_LINE),"column":$(DAP_ZERO_BASED_MAPPED_COLUMN)'
	dap_breakpoint_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir","sourcePathRoot":"/workspace"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"/workspace/missing.elisa"},"breakpoints":[]}}' '{"seq":4,"type":"request","command":"setBreakpoints","arguments":{"source":{"name":"main.elisa","path":"/workspace/main.elisa","sourceReference":0},"breakpoints":[{"line":42},{"line":99}]}}' '{"seq":5,"type":"request","command":"continue"}' '{"seq":6,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' '{"seq":7,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"/workspace/main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":8,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":99},"breakpoints":[]}}' '{"seq":9,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":7,"path":"/workspace/missing.elisa"},"breakpoints":[]}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_source_breakpoints=$$(printf %s "$$dap_breakpoint_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_source_breakpoints" | grep -F '"command":"setBreakpoints","success":false'; echo "$$dap_source_breakpoints" | grep -F '"command":"setBreakpoints","success":true,"body":{"breakpoints":[{"id":1,"verified":true,"line":42},{"id":2,"verified":false,"line":99}]}}'; echo "$$dap_source_breakpoints" | grep -F '"source":{"name":"main.elisa","path":"/workspace/main.elisa"}'; echo "$$dap_source_breakpoints" | grep -F '"reason":"breakpoint"'; echo "$$dap_source_breakpoints" | grep -F '"stackFrames":[{"id":$(DAP_FIRST_STOP_FRAME_ID),"name":"main","line":42,'
	dap_windows_path_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir","sourcePathRoot":"C:\\workspace"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"C:\\workspace\\main.elisa"},"breakpoints":[{"line":42}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' '{"seq":6,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"C:/workspace/main.elisa"},"breakpoints":[{"line":42}]}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_windows_paths=$$(printf %s "$$dap_windows_path_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_windows_paths" | grep -F '"command":"setBreakpoints","success":true,"body":{"breakpoints":[{"id":1,"verified":true,"line":42}]}}'; echo "$$dap_windows_paths" | grep -F '"source":{"name":"main.elisa","path":"C:/workspace/main.elisa"}'; echo "$$dap_windows_paths" | grep -F '"reason":"breakpoint"'
	dap_zero_based_breakpoint_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize","arguments":{"linesStartAt1":false}}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":7},"breakpoints":[{"line":41}]}}' '{"seq":4,"type":"request","command":"continue"}' '{"seq":5,"type":"request","command":"stackTrace","arguments":{"threadId":1}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_zero_based_breakpoints=$$(printf %s "$$dap_zero_based_breakpoint_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_zero_based_breakpoints" | grep -F '"command":"setBreakpoints","success":true,"body":{"breakpoints":[{"id":1,"verified":true,"line":41}]}}'; echo "$$dap_zero_based_breakpoints" | grep -F '"reason":"breakpoint"'; echo "$$dap_zero_based_breakpoints" | grep -F '"stackFrames":[{"id":$(DAP_FIRST_STOP_FRAME_ID),"name":"main","line":41,'
	launch_payload='{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}'; launch_length=$$(printf %s "$$launch_payload" | wc -c | tr -d ' '); dap_timeline=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: %s\r\n\r\n%sContent-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 43\r\n\r\n{"seq":4,"type":"request","command":"next"}Content-Length: 76\r\n\r\n{"seq":5,"type":"request","command":"stackTrace","arguments":{"threadId":1}}Content-Length: 47\r\n\r\n{"seq":6,"type":"request","command":"stepBack"}Content-Length: 76\r\n\r\n{"seq":7,"type":"request","command":"stackTrace","arguments":{"threadId":1}}Content-Length: 43\r\n\r\n{"seq":8,"type":"request","command":"next"}Content-Length: 76\r\n\r\n{"seq":9,"type":"request","command":"stackTrace","arguments":{"threadId":1}}Content-Length: 44\r\n\r\n{"seq":10,"type":"request","command":"next"}Content-Length: 77\r\n\r\n{"seq":11,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' "$$launch_length" "$$launch_payload" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_timeline" | grep -F '"line":42,"column":$(DAP_EXPECTED_MAPPED_COLUMN)'; echo "$$dap_timeline" | grep -F '"line":41,"column":$(DAP_EXPECTED_MAPPED_COLUMN)'; echo "$$dap_timeline" | grep -F '"line":$(DAP_UNKNOWN_SOURCE_LINE),"column":$(DAP_UNKNOWN_SOURCE_LINE)}]}}'
	dap_variables_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize","arguments":{"supportsVariableType":true}}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stepIn"}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_DAP_FRAME_ID)}}' '{"seq":9,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_DAP_LOCAL_REFERENCE)}}' '{"seq":10,"type":"request","command":"stepIn"}' '{"seq":11,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_DAP_FRAME_ID)}}' '{"seq":12,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_DAP_LOCAL_REFERENCE)}}' '{"seq":13,"type":"request","command":"scopes","arguments":{"frameId":$(DAP_VARIABLES_AFTER_STEP_FRAME_ID)}}' '{"seq":14,"type":"request","command":"variables","arguments":{"variablesReference":$(DAP_VARIABLES_AFTER_STEP_REFERENCE)}}' '{"seq":15,"type":"request","command":"evaluate","arguments":{"expression":"local0"}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_variables=$$(printf %s "$$dap_variables_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_variables" | grep -F '"variablesReference":$(COMPILER_EDIR_DAP_LOCAL_REFERENCE),"expensive":false'; echo "$$dap_variables" | grep -F '"name":"local0","value":"17","type":"i64"'; echo "$$dap_variables" | grep -F '"name":"local1","value":"29","type":"i64"'; echo "$$dap_variables" | grep -F '"command":"variables","success":false,"message":"variables reference is stale"'; echo "$$dap_variables" | grep -F '"command":"scopes","success":false'; echo "$$dap_variables" | grep -F '"variablesReference":$(DAP_VARIABLES_AFTER_STEP_REFERENCE),"expensive":false'; echo "$$dap_variables" | grep -F '"result":"29","type":"integer","variablesReference":0'
	dap_variables_without_type_input=$$(for payload in '{"seq":1,"type":"request","command":"initialize"}' '{"seq":2,"type":"request","command":"launch","arguments":{"program":"$(BUILD)/edir-fixture.edir"}}' '{"seq":3,"type":"request","command":"pause"}' '{"seq":4,"type":"request","command":"stepIn"}' '{"seq":5,"type":"request","command":"stepIn"}' '{"seq":6,"type":"request","command":"stepIn"}' '{"seq":7,"type":"request","command":"stepIn"}' '{"seq":8,"type":"request","command":"scopes","arguments":{"frameId":$(COMPILER_EDIR_DAP_FRAME_ID)}}' '{"seq":9,"type":"request","command":"variables","arguments":{"variablesReference":$(COMPILER_EDIR_DAP_LOCAL_REFERENCE)}}' '{"seq":10,"type":"request","command":"evaluate","arguments":{"expression":"local0"}}'; do frame_length=$$(printf %s "$$payload" | wc -c | tr -d ' '); printf 'Content-Length: %s\r\n\r\n%s' "$$frame_length" "$$payload"; done); dap_variables_without_type=$$(printf %s "$$dap_variables_without_type_input" | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_variables_without_type" | grep -F '"name":"local0","value":"17","variablesReference":0'; echo "$$dap_variables_without_type" | grep -F '"result":"17","variablesReference":0'; ! echo "$$dap_variables_without_type" | grep -F '"type":"i64"'; ! echo "$$dap_variables_without_type" | grep -F '"type":"integer"'
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

# Included Elisa modules and compiler upgrades must invalidate executable and test products.
$(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server $(BUILD)/elisa-debugger-cli $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-edir-codec-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-managed-trace-service-check $(BUILD)/elisa-debugger-managed-memory-write-history-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-protocol-encoding-check $(BUILD)/elisa-debugger-protocol-framing-check $(BUILD)/elisa-debugger-remote-authentication-check $(BUILD)/elisa-debugger-remote-authorization-check $(BUILD)/elisa-debugger-trace-storage-decode-check $(BUILD)/elisa-debugger-trace-reader-encoded-check $(BUILD)/elisa-debugger-checkpoint-state-check $(BUILD)/elisa-debugger-trace-manifest-status-check $(BUILD)/elisa-debugger-adapter-recording-bounds-check $(BUILD)/elisa-debugger-runtime-status-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-request-operands-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-integration-surface-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check: $(ELISA_BUILD_INPUTS)
