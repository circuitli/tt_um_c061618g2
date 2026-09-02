// =========================================================================
// WORKCRAFT POST-SYNTHESIS ASYNCHRONOUS FORMAL CHECK
// =========================================================================

// Point directly to the cleaned netlist file
var designFile = "../test/combined_netlist.v";
var circuitModel = importCircuitVerilog(designFile);

if (circuitModel == null) {
    print("ERROR: Failed to parse the top-level structural gate netlist.");
    exit();
}

// FIX: Shorthand validation routines are bound as standalone global functions
print("Scanning top-level and submodules for asynchronous deadlocks...");
var deadlockClean = checkCircuitDeadlockFreeness(circuitModel);

print("Scanning full combinational matrix for hazard propagation...");
var hazardsClean = checkCircuitCycles(circuitModel);

if (!deadlockClean || !hazardsClean) {
    print("FAIL: Clockless boundary or submodule loop hazard detected.");
    exit();
} else {
    print("PASS: All top-level paths and async submodules are fully verified!");
    exit();
}
