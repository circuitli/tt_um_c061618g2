// =========================================================================
// WORKCRAFT POST-SYNTHESIS ASYNCHRONOUS FORMAL CHECK
// =========================================================================

// Disable the automated background directory scanning via the real framework API
setConfigVar("VerilogImporter.searchPaths", "");

var designFile = "../test/combined_netlist.v";
var work = importCircuitVerilog(designFile, "tt_um_c061618g2");

if (work == null) {
    print("❌ ERROR: Failed to parse the top-level structural gate netlist.");
    java.lang.System.exit(1);
}

// 1. Scan for deadlocks (Converts the native Java Boolean into a JavaScript primitive)
print("Scanning top-level and submodules for asynchronous deadlocks...");
var deadlockClean = Boolean(checkCircuitDeadlockFreeness(work));

// 2. Scan for unbroken combinational cycles (Converts the clean execution return into a primitive)
print("Scanning full combinational matrix for hazard-inducing cyclic paths...");
var hazardsClean = Boolean(checkCircuitCycles(work));

print("----------------------------------------------------------------------");

// =========================================================================
// 🏁 CLOCKLESS ASYNCHRONOUS EXIT CRITERIA
// Both variables now evaluate to clean JavaScript boolean primitives.
// If your LibreLane layout contains no cycles, hazardsClean evaluates to true!
// =========================================================================
if (deadlockClean === false || hazardsClean === false) {
    print("❌ FAIL: Asynchronous verification violations detected!");

    if (deadlockClean === false) {
        print("⚠️  - Deadlock/freeze state identified.");
    }
    if (hazardsClean === false) {
        print("⚠️  - Unbroken combinational loop hazard identified.");
    }
    print("----------------------------------------------------------------------");
    java.lang.System.exit(1);
} else {
    print("----------------------------------------------------------------------");
    print("✅ PASS: Mathematical deadlock freeness and clockless loop pathways verified!");
    print("----------------------------------------------------------------------");
    java.lang.System.exit(0);
}
