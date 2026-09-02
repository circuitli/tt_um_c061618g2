// =========================================================================
// WORKCRAFT POST-SYNTHESIS ASYNCHRONOUS FORMAL CHECK
// =========================================================================

var designFile = "../test/combined_netlist.v";
var circuitModel = importCircuitVerilog(designFile);

if (circuitModel == null) {
    print("❌ ERROR: Failed to parse the top-level structural gate netlist.");
    java.lang.System.exit(1);
}

// =========================================================================
// 🛠️ AUTOMATED LOOP BREAKER ATTACHMENT
// We scan the graph model for all pins belonging to your MMU filter latches
// ('u_latch_inst') and toggle their pathBreaker flag to isolate the loop.
// =========================================================================
print("🔧 Initializing clockless state boundaries via graph properties...");
var components = circuitModel.getFunctionComponents().toArray();

for (var i = 0; i < components.length; i++) {
    var comp = components[i];
    var compName = circuitModel.getComponentReference(comp);

    // Target only the instances flagged in your cycle log trace
    if (compName.indexOf("u_latch_inst") !== -1) {
        var contacts = comp.getFunctionContacts().toArray();
        for (var j = 0; j < contacts.length; j++) {
            var pin = contacts[j];

            // Set the path breaker attribute on the loop pin
            // (Typically input pins like hold/set that take feedback wires)
            if (pin.isInput()) {
                pin.setPathBreaker(true);
            }
        }
    }
}

// 1. Scan for deadlocks
print("Scanning top-level and submodules for asynchronous deadlocks...");
var deadlockClean = Boolean(checkCircuitDeadlockFreeness(circuitModel));

// 2. Scan for unbroken cycles (Should now evaluate to clean PASS)
print("Scanning full combinational matrix for hazard-inducing cyclic paths...");
var hazardsClean = Boolean(checkCircuitCycles(circuitModel));

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
