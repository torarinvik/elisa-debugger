ELISA_COMPILER ?= ../Elisa-compiler/scripts/elisac_stage1.sh
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
# The sibling compiler checkout may contain unrelated uncommitted source edits.
# Keep the local debugger build usable by default; CI can set this to 0 for the
# strict product-freshness gate.
ELISA_ALLOW_STALE_STAGE1 ?= 1
# Elisa's stage1 compiler does not emit make dependency files for `include`d
# modules.  Keep focused checks dependent on every source module so a changed
# include cannot leave a silently stale executable behind.
ELISA_SOURCE_FILES := $(shell find src -type f -name '*.elisa')

.PHONY: check build server dap-server cli module-check ffi-check smoke managed-inspection-check managed-service-check terminal-checkpoint-check protocol-events-check protocol-encoding-check protocol-framing-check server-buffer-check remote-authentication-check remote-artifacts-check trace-storage-decode-check trace-reader-encoded-check checkpoint-state-check trace-manifest-status-check adapter-recording-bounds-check runtime-status-check source-store-check request-whitespace-check cli-commands-check value-store-check historical-values-check query-engine-check query-evaluator-check breakpoint-manager-check advanced-analysis-check integration-contract-check integration-surface-check trace-retention-check coordinator-seek-check capabilities-check dap-payload-check trace-codec-check trace-recording-check trace-bundle-check edir-codec-check timeline-capability-check clean

build: $(BUILD)/elisa-debugger

server: $(BUILD)/elisa-debugger-server

dap-server: $(BUILD)/elisa-debugger-dap-server

cli: $(BUILD)/elisa-debugger-cli

module-check: $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-edir-codec-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-protocol-encoding-check $(BUILD)/elisa-debugger-protocol-framing-check $(BUILD)/elisa-debugger-remote-authentication-check $(BUILD)/elisa-debugger-trace-storage-decode-check $(BUILD)/elisa-debugger-trace-reader-encoded-check $(BUILD)/elisa-debugger-checkpoint-state-check $(BUILD)/elisa-debugger-trace-manifest-status-check $(BUILD)/elisa-debugger-adapter-recording-bounds-check $(BUILD)/elisa-debugger-runtime-status-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-query-evaluator-check $(BUILD)/elisa-debugger-breakpoint-manager-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-integration-surface-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check $(BUILD)/elisa-debugger-dap-payload-check $(BUILD)/elisa-debugger-ffi-probe

# Keep the remote artifact transfer regression in the aggregate module gate.
module-check: $(BUILD)/elisa-debugger-remote-artifacts-check
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
	"$(BUILD)/elisa-debugger-protocol-events-check"
	"$(BUILD)/elisa-debugger-protocol-encoding-check"
	"$(BUILD)/elisa-debugger-protocol-framing-check"
	"$(BUILD)/elisa-debugger-trace-storage-decode-check"
	"$(BUILD)/elisa-debugger-trace-reader-encoded-check"
	"$(BUILD)/elisa-debugger-remote-authentication-check"
	"$(BUILD)/elisa-debugger-checkpoint-state-check"
	"$(BUILD)/elisa-debugger-trace-manifest-status-check"
	"$(BUILD)/elisa-debugger-adapter-recording-bounds-check"
	"$(BUILD)/elisa-debugger-runtime-status-check"
	"$(BUILD)/elisa-debugger-source-store-check"
	"$(BUILD)/elisa-debugger-request-whitespace-check"
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
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

managed-inspection-check: $(BUILD)/elisa-debugger-managed-inspection-check
	"$(BUILD)/elisa-debugger-managed-inspection-check"

managed-service-check: $(BUILD)/elisa-debugger-managed-service-check
	"$(BUILD)/elisa-debugger-managed-service-check"

$(BUILD)/elisa-debugger-terminal-checkpoint-check: tests/terminal_checkpoint_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

terminal-checkpoint-check: $(BUILD)/elisa-debugger-terminal-checkpoint-check
	"$(BUILD)/elisa-debugger-terminal-checkpoint-check"

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

dap-payload-check: $(BUILD)/elisa-debugger-dap-payload-check
	"$(BUILD)/elisa-debugger-dap-payload-check"

$(BUILD)/elisa-debugger-timeline-capability-check: tests/timeline_capability_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

timeline-capability-check: $(BUILD)/elisa-debugger-timeline-capability-check
	"$(BUILD)/elisa-debugger-timeline-capability-check"

ffi-check: $(BUILD)/elisa-debugger-ffi-probe
	test "$$(printf 'ELI' | "$(BUILD)/elisa-debugger-ffi-probe")" = 'ELI'

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

protocol-encoding-check: $(BUILD)/elisa-debugger-protocol-encoding-check
	"$(BUILD)/elisa-debugger-protocol-encoding-check"

$(BUILD)/elisa-debugger-checkpoint-state-check: tests/checkpoint_state_check.elisa $(ELISA_SOURCE_FILES)
	mkdir -p $(BUILD)
	ELISA_ALLOW_STALE_STAGE1="$(ELISA_ALLOW_STALE_STAGE1)" $(ELISA_RUNTIME_ENV) $(ELISA_COMPILER) -emit exe -O0 -o "$@" "$<"

checkpoint-state-check: $(BUILD)/elisa-debugger-checkpoint-state-check
	"$(BUILD)/elisa-debugger-checkpoint-state-check"

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

smoke: check server dap-server cli ffi-check
	printf '655360 ' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf '21 {' | "$(BUILD)/elisa-debugger-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 655360\r\n\r\n' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf '21 {"method":"discover"}\n' | "$(BUILD)/elisa-debugger-server" | grep -F '"protocolMajor":1' | grep -F '"productVersion":"0.1.0"' | grep -F '"installationHealthy":true'
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
	printf 'Content-Length: 55\r\n\r\n{"seq":1,"type":"request","command":"initialize\"junk"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -q '"success":false'; test "$$?" -eq 0
	printf 'Content-Length: 55\r\n\r\n{"seq":1,"type":"request\"junk","command":"initialize"}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 50\r\n\r\n{"seq":1,"type":"request","command":"initialize",}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 56\r\n\r\n{"seq":1,"type":"request","command":"initialize",,"x":1}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 58\r\n\r\n{"seq":1,"type":"request","command":"initialize","x":[{]}}' | "$(BUILD)/elisa-debugger-dap-server" >/dev/null; test "$$?" -eq 2
	printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 49\r\n\r\n{"seq":4,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server" | grep -F '"stackFrames":[{"id":1,"name":"main","line":1'
	dap_timeline=$$(printf 'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}Content-Length: 45\r\n\r\n{"seq":2,"type":"request","command":"launch"}Content-Length: 44\r\n\r\n{"seq":3,"type":"request","command":"pause"}Content-Length: 43\r\n\r\n{"seq":4,"type":"request","command":"next"}Content-Length: 49\r\n\r\n{"seq":5,"type":"request","command":"stackTrace"}Content-Length: 47\r\n\r\n{"seq":6,"type":"request","command":"stepBack"}Content-Length: 49\r\n\r\n{"seq":7,"type":"request","command":"stackTrace"}' | "$(BUILD)/elisa-debugger-dap-server"); echo "$$dap_timeline" | grep -F '"line":2'; echo "$$dap_timeline" | grep -F '"line":1'
	printf 'launch\npause\ncontinue\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'
	printf 'launch\npause\nseek 1\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=2'
	printf 'launch\npause\nsaveTrace\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=1'
	printf 'run\nclose\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=0'
	printf 'launch\r\npause\r\n' | "$(BUILD)/elisa-debugger-cli" | grep -F 'ok generation=1'

clean:
	rm -rf $(BUILD)

# Included Elisa modules must invalidate executable and test products too.
$(BUILD)/elisa-debugger-server $(BUILD)/elisa-debugger-dap-server $(BUILD)/elisa-debugger-cli $(BUILD)/elisa-debugger-module-core-check $(BUILD)/elisa-debugger-module-data-check $(BUILD)/elisa-debugger-module-protocol-check $(BUILD)/elisa-debugger-module-trace-codec-check $(BUILD)/elisa-debugger-module-trace-recording-check $(BUILD)/elisa-debugger-module-trace-bundle-check $(BUILD)/elisa-debugger-edir-call-check $(BUILD)/elisa-debugger-edir-codec-check $(BUILD)/elisa-debugger-session-check $(BUILD)/elisa-debugger-managed-inspection-check $(BUILD)/elisa-debugger-managed-service-check $(BUILD)/elisa-debugger-protocol-events-check $(BUILD)/elisa-debugger-protocol-encoding-check $(BUILD)/elisa-debugger-protocol-framing-check $(BUILD)/elisa-debugger-remote-authentication-check $(BUILD)/elisa-debugger-trace-storage-decode-check $(BUILD)/elisa-debugger-trace-reader-encoded-check $(BUILD)/elisa-debugger-checkpoint-state-check $(BUILD)/elisa-debugger-trace-manifest-status-check $(BUILD)/elisa-debugger-adapter-recording-bounds-check $(BUILD)/elisa-debugger-runtime-status-check $(BUILD)/elisa-debugger-source-store-check $(BUILD)/elisa-debugger-request-whitespace-check $(BUILD)/elisa-debugger-cli-commands-check $(BUILD)/elisa-debugger-value-store-check $(BUILD)/elisa-debugger-historical-values-check $(BUILD)/elisa-debugger-query-engine-check $(BUILD)/elisa-debugger-advanced-analysis-check $(BUILD)/elisa-debugger-integration-contract-check $(BUILD)/elisa-debugger-integration-surface-check $(BUILD)/elisa-debugger-trace-retention-check $(BUILD)/elisa-debugger-coordinator-seek-check $(BUILD)/elisa-debugger-capabilities-check: $(shell find src -type f -name '*.elisa')
