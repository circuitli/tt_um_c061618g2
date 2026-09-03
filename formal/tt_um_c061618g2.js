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

// FIX: Extract the actual underlying Circuit Graph Model from the work wrapper
var circuitModel = work.getModel();

// =========================================================================
// 🛠️ AUTOMATED LOOP BREAKER ATTACHMENT
// We scan the graph model for all components matching your lockless MMU 
// filter latches ('u_latch_inst') and tag their input pins to break the loop.
// =========================================================================
print("🔧 Initializing clockless state boundaries via graph properties...");
var components = circuitModel.getFunctionComponents().toArray();

for (var i = 0; i < components.length; i++) {
    var comp = components[i];
    var compName = circuitModel.getComponentReference(comp);

    // Target only the latch instances flagged in your clockless cycle trace
    if (compName.indexOf("u_latch_inst") !== -1) {
        var contacts = comp.getFunctionContacts().toArray();
        for (var j = 0; j < contacts.length; j++) {
            var pin = contacts[j];

            // Flag inputs as path breakers so the analyzer treats them as state limits
            if (pin.isInput()) {
                pin.setPathBreaker(true);
            }
        }
    }
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
