// =========================================================================
// WORKCRAFT POST-SYNTHESIS ASYNCHRONOUS FORMAL CHECK
// =========================================================================

var designFile = "../test/combined_netlist.v";
// importCircuitVerilog returns a Framework Work/WorkspaceEntry object
var work = importCircuitVerilog(designFile);

if (work == null) {
    print("❌ ERROR: Failed to parse the top-level structural gate netlist.");
    java.lang.System.exit(1);
}

// 1. Scan for deadlocks (Must return true for your clockless handshake paths)
print("Scanning top-level and submodules for asynchronous deadlocks...");
var deadlockClean = Boolean(checkCircuitDeadlockFreeness(work));

// 2. Scan for unbroken cycles (Should now evaluate to clean true/PASS)
print("Scanning full combinational matrix for hazard-inducing cyclic paths...");
var hazardsClean = Boolean(checkCircuitCycles(work));

print("----------------------------------------------------------------------");

// 3. Script Exit Evaluation
if (deadlockClean === false || hazardsClean === false) {
    print("❌ FAIL: Asynchronous verification violations detected!");
    if (deadlockClean === false) print("⚠️  - Deadlock/freeze state identified.");
    if (hazardsClean === false) print("⚠️  - Unexpected unbroken combinational loop hazard identified.");
    print("----------------------------------------------------------------------");
    java.lang.System.exit(1);
} else {
    print("✅ PASS: Mathematical deadlock freeness and clockless loop pathways verified!");
    print("----------------------------------------------------------------------");
    java.lang.System.exit(0);
}
