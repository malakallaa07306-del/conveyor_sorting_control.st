# PLC-Based Conveyor Sorting Control System

An industrial-grade control automation pipeline designed in **Structured Text (ST)** adhering to the **IEC 61131-3** international standard. This project serves as an Advanced Mastery Phase developed with **DecodeLabs** to simulate an enterprise factory floor conveyor sorting application.

The control architecture is built entirely upon a highly deterministic cyclic scan loop (1ms-100ms Execution Time), preventing software-level crashes and guaranteeing real-time responsiveness.

---

## 🛠️ Hardware I/O Register Architecture

Physical automation hardware devices are strictly mapped to discrete PLC memory tags with appropriate debouncing filters implemented:

* **Digital Inputs (%I Memory Base):**
    * `i_Start_PB` (`%I0.0`): Start Push Button - Normally Open
    * `i_Prox_Sensor` (`%I0.1`): Main Entry Package Proximity Sensor
    * `i_EStop_Mon` (`%I0.2`): Dual-Contact Safety Relay Hardware Monitor Line
    * `i_Stop_PB` (`%I0.3`): Stop Push Button - Normally Closed
    * `i_Tall_Sensor` (`%I0.4`): High-Level Optic Height Sizing Sensor

* **Digital Outputs (%Q Memory Base):**
    * `q_Conv_Motor` (`%Q1.0`): Conveyor Belt Drive Contactor
    * `q_Reject_Push` (`%Q1.1`): Diverter Actuator Pneumatic Solenoid Valve
    * `q_Warn_Light` (`%Q1.2`): Amber Safety Warning Beacon

---

## 📐 Industrial Logic & Mathematical Formulations

### 1. Finite State Machine (FSM) Topology
To enforce strict mutual exclusivity and prevent physical output race hazards, the logic routes sequentially through distinct states:
* **Idle ($S=1$):** Motors de-energized, pushers retracted, system safe.
* **Running ($S=2$):** Conveyor contactor active (`%Q1.0 = TRUE`), actively monitoring streams.
* **Sorting ($S=3$):** Triggered by box discovery to handle sorting sequences.
* **Fault ($S=4$):** Immediate fail-safe lockdown trip.

### 2. Signal Edge Triggering (R_TRIG)
To eliminate spatial-temporal mismatches where a physical box blocks an optical line for consecutive PLC scans, all counting inputs are filtered via positive edge detection blocks:
$$\text{Q\_pulse} = \text{Input\_current} \ \text{AND NOT}(\text{Input\_previous})$$
This ensures exactly one digital pulse per item regardless of transit duration.

### 3. Transit Delay Mathematics (TON Block)
Given a physical distance $d = 0.75\text{ m}$ between the height sensor and the reject pusher, and a constant nominal belt velocity $v = 0.5\text{ m/s}$:
$$t = \frac{d}{v} \rightarrow \frac{0.75\text{ m}}{0.5\text{ m/s}} = 1.5\text{ seconds}$$
An On-Delay Timer (`TON`) with a preset time (`PT`) of `T#1500MS` delays pneumatics actuation to hit moving packages precisely.

### 4. Hardwired Safety Relay Cutoffs (NFPA 79 & IEC 60204-1)
Software safety configurations fail under CPU lockups. This design incorporates a dual-contact physical layout: Contact 1 hardwires directly into an independent Safety Relay to drop motor power instantly (Stop Category 0), bypassing the PLC completely. Contact 2 streams to `%I0.2` purely for software latch diagnostics.

---

## 💻 Environment & Tools
* **Programming Language:** IEC 61131-3 Structured Text (ST)
* **Virtual Commissioning Pipeline:** Loaded into Siemens S7-PLCSIM interfaced via a localized handshake link to a 3D physics emulator environment.
