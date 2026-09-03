// =========================================================================
// WORKCRAFT POST-SYNTHESIS ASYNCHRONOUS FORMAL CHECK
// =========================================================================

var designFile = "../test/combined_netlist.v";
var work = importCircuitVerilog(designFile);

if (work == null) {
    print("❌ ERROR: Failed to parse the top-level structural gate netlist.");
    java.lang.System.exit(1);
}

// 1. Scan for deadlocks (Returns a clean true/false boolean primitive)
print("Scanning top-level and submodules for asynchronous deadlocks...");
var deadlockClean = Boolean(checkCircuitDeadlockFreeness(work));

// 2. Scan for unbroken combinational cycles 
print("Scanning full combinational matrix for hazard-inducing cyclic paths...");
var cyclesReport = checkCircuitCycles(work); // This returns a descriptive log string

print("----------------------------------------------------------------------");

// =========================================================================
// 🏁 CLOCKLESS ASYNCHRONOUS EXIT CRITERIA
// If deadlockClean is false, fail immediately.
// If the cycles report string contains "[ERROR]" or mentions "components",
// we catch it explicitly and fail the pipeline run.
// =========================================================================
var hasCycles = (cyclesReport != null && (cyclesReport.indexOf("ERROR") !== -1 || cyclesReport.indexOf("components") !== -1));

if (deadlockClean === false || hasCycles === true) {
    print("❌ FAIL: Asynchronous verification violations detected!");

    if (deadlockClean === false) {
        print("⚠️  - Deadlock/freeze state identified.");
    }
    if (hasCycles === true) {
        print("⚠️  - Unbroken combinational loop hazard identified.");
    }
    print("----------------------------------------------------------------------");
    java.lang.System.exit(1);
} else {
    print("✅ PASS: Mathematical deadlock freeness and clockless loop pathways verified!");
    print("----------------------------------------------------------------------");
    java.lang.System.exit(0);
}
