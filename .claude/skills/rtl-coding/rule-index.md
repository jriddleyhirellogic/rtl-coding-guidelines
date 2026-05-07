# RTL Coding Rule Index

Auto-generated index of all NTL_* rules. Each entry: `RULE_ID` — message.
Read the corresponding `<RULE_ID>.html` for full description, severity, examples, and policy.

## CLK

- `NTL_CLK01` — Use only one clock domain
- `NTL_CLK02` — Use only one clock signal per unit
- `NTL_CLK03` — Use only one edge of the clock %s1
- `NTL_CLK04` — Do not use internally generated clock
- `NTL_CLK05` — All asynchronous inputs to a clock system must be clocked twice.
- `NTL_CLK07` — Avoid gated clocks unless absolutely necessary
- `NTL_CLK08` — If gated clocks are necessary, isolate them and make them global
- `NTL_CLK09` — All clock signals should be generated in a module driven by a single external clock
- `NTL_CLK10` — Clock signal gated with an OR gate %s.
- `NTL_CLK11` — Clock signal gated with an AND gate %s.
- `NTL_CLK12` — Clock signal gated with another combinatorial cell
- `NTL_CLK13` — Buffer on clock path detected
- `NTL_CLK14` — Inverter on clock path detected
- `NTL_CLK15` — Clock pin not connected to clock net
- `NTL_CLK17` — Reconvergent path on clock tree detected: %s
- `NTL_CLK18` — Try to concentrate the clock generation circuitry at the top-level of the design
- `NTL_CLK19` — Do not add XOR or XNOR on clock path
- `NTL_CLK20` — Use only OR gate for joined clock
- `NTL_CLK21` — Pulse generator created by self flip-flop
- `NTL_CLK22` — Clock chopper/extender detection
- `NTL_CLK23` — Multiple asynchronous clock domain signals converging on &lt;gate_name&gt;
- `NTL_CLK24` — Multibit control signal crossing clock domain should be Gray coded
- `NTL_CLK25` — Control signal crossing clock domain
- `NTL_CLK26` — Control signal crossing clock domain with data transfer
- `NTL_CLK27` — Control signal crossing clock domain without data transfer
- `NTL_CLK28` — Use only user-specified cells for clock gating
- `NTL_CLK29` — Primary input feeds multiple clock domains
- `NTL_CLK30` — Reset is used in multiple clock domains
- `NTL_CLK31` — Clock pin is connected to the select pin of the MUX
- `NTL_CLK33` — Detect the combinational circuit other than selector (multiplexer) which merges the multiple clocks
- `NTL_CLK34` — Do not use meta-stable flip-flop
- `NTL_CLK35` — Do not use internally generated clock derived from sequential element: %s1
- `NTL_CLK36` — Do not use cells that have sdf_cond attribute in clock line.
- `NTL_CLK37` — Gated clock cell which has more than 2 inputs is found
- `NTL_CLK38` — Loop is found, output of FF is connected to own reset/set/clock pin.
- `NTL_CLK39` — Multiple combinational paths are found on the clock path
- `NTL_CLK42` — SET and RESET of F/F which drives enable signal must be clamped
- `NTL_CLK44` — Clock gating enable is illegal
- `NTL_CLK45` — Do not assign fix value to enable signal of clock gating cell %s1
- `NTL_CLK46` — Do not put DB cell that does not have timing-arc in out-pin on clock line
- `NTL_CLK47` — Clock of flip-flop/latch is unconstrained
- `NTL_CLK48` — Clock is constrained and tied to constant in test mode
- `NTL_CLK49` — Clock signal gated with a XOR gate %s.
- `NTL_CLK50` — Clock signal gated with a MUX.
- `NTL_CLK51` — Identical gated clocks detected %s.
- `NTL_CLK52` — Detected the cell which contains a latch controlling the gated clock inside %s.
- `NTL_CLK53` — Detected the cell which contains multiple gated clocks.

## CON

- `NTL_CON01` — Unconnected top-level input port %s1
- `NTL_CON02` — Unconnected top-level output port %s1
- `NTL_CON03` — Unconnected top-level inout port
- `NTL_CON04` — All input pins tied together
- `NTL_CON05` — Some input pins tied together %s
- `NTL_CON06` — Input pin tied to supply
- `NTL_CON08` — Floating output pin
- `NTL_CON09` — All output pins are unconnected (dead gates)
- `NTL_CON10` — Output tied to supply
- `NTL_CON12` — Undriven net: %s1
- `NTL_CON12A` — Undriven internal net %s1
- `NTL_CON12B` — Undriven hierarchical pin: %s1
- `NTL_CON12C` — Undriven port: %s1
- `NTL_CON13` — Non-driving net: %s1
- `NTL_CON13A` — Non-driving internal net: %s1
- `NTL_CON13B` — Non-driving hierarchical pin: %s1
- `NTL_CON13C` — Non-driving port: %s1
- `NTL_CON14` — All input pins must be connected
- `NTL_CON15` — Power rails belonging to different supply types should not short %s1
- `NTL_CON16` — Nets or cell pins should not be tied to logic 0 / logic 1
- `NTL_CON17` — Do not connect tie off cell to logic 0 /logic 1
- `NTL_CON18` — There is output port, but it is not connected internally %s1
- `NTL_CON19` — There is input port that is connected to both input and output of cell
- `NTL_CON20` — Connection of diodes
- `NTL_CON21` — Diodes should be used at top level
- `NTL_CON22` — Incorrect connection: Module input is connected to output of its sub-module
- `NTL_CON23` — Incorrect connection: Module output is connected to input of its sub-module
- `NTL_CON24` — Cells output is fixed value
- `NTL_CON25` — Number of pin-pairs in design.
- `NTL_CON26` — Do not connect the block to the prohibited pin
- `NTL_CON27` — The specified pin of the block should be connected to the designated pin
- `NTL_CON28` — Should not use inout ports in user defined modules/instances: %s1
- `NTL_CON29` — Should not connect the output ports of user defined modules/instances to VDD/GND internally: %s1
- `NTL_CON32` — Change on net has no effect on any of the outputs.
- `NTL_CON33` — None of the inputs have any effect on net.

## DFT

- `NTL_DFT02` — Separate DFT functionality from regular functionality
- `NTL_DFT03` — Full scan test is required
- `NTL_DFT07` — Internally generated output enable signal must be observable/controllable
- `NTL_DFT08` — No contention may take place during scan-test mode
- `NTL_DFT09` — Scan input and scan output must be primary input/output
- `NTL_DFT10` — Scan chain too long (default is 10)
- `NTL_DFT11` — Flip-flops in a scan chain must have a common scan clock
- `NTL_DFT12` — Separate scan chains for different clock domains
- `NTL_DFT13` — Use a single clock edge for a given scan chain
- `NTL_DFT14` — Use a single clock for a given scan chain
- `NTL_DFT15` — All scan-in input ports must be controllable from the top
- `NTL_DFT16` — All scan-out output ports must be observable from the top
- `NTL_DFT17` — Scan-in used in combinatorial part
- `NTL_DFT22` — Use one synchronous clock (positive or negative edge) during test
- `NTL_DFT23` — Clock signal must be controllable
- `NTL_DFT24` — Internally generated clock must be observable/controllable
- `NTL_DFT25` — Make sure that all sequential scan cells are driven with a test clock while the scan mode is active
- `NTL_DFT26` — Scan clock control flip-flop data
- `NTL_DFT27` — Scan clock control I/O cell
- `NTL_DFT28` — Scan clock should be called scan_clk...
- `NTL_DFT29` — Asynchronous set/reset inputs of flip-flops must be inactive during scan test
- `NTL_DFT30` — Do not use asynchronous presets or clears driven by combinatorial logic or by the output of a flip-flop
- `NTL_DFT31` — Internally generated reset/set must be observable/controllable
- `NTL_DFT32` — Connect all non-observable nodes of the design to an XOR tree
- `NTL_DFT34` — Use data lookup latches for clock domain crossings
- `NTL_DFT36` — Do not use scan-type flip-flops for functional mode
- `NTL_DFT37` — Insert scan flip-flop around black box
- `NTL_DFT38` — Flip-flop without reset detected
- `NTL_DFT39` — Flip-flop without scan-in detected
- `NTL_DFT40` — Flip-flop without scan-enable detected
- `NTL_DFT41` — Flip-flop with tied input value detected
- `NTL_DFT42` — Flip-flop input pin is unconnected
- `NTL_DFT43` — Flip-flop reset pin is unconnected
- `NTL_DFT44` — Flip-flop set pin is unconnected
- `NTL_DFT45` — Flip-flop clock pin is unconnected
- `NTL_DFT46` — Flip-flop scan-in pin is unconnected
- `NTL_DFT47` — Flip-flop scan-enable pin is unconnected
- `NTL_DFT48` — Flip-flop scan-enable pin not connected to scan-enable signal
- `NTL_DFT49` — Flip-flop scan-out pin is unconnected
- `NTL_DFT52` — All set/reset pins must be controllable during test mode
- `NTL_DFT53` — Scan-enable must be controllable from the top
- `NTL_DFT54` — Insert test enable for scan test
- `NTL_DFT55` — Test-enable signal must be generated from the scan-mode or directly from the primary inputs
- `NTL_DFT56` — Scan-enable used in combinatorial part
- `NTL_DFT57` — Inputs and Outputs of Black Box should be connected to FFs
- `NTL_DFT58` — Gate signal of latch should be thru during test mode

## LAN

- `NTL_LAN01` — Tri assignment target must be a port
- `NTL_LAN15` — Unused signals
- `NTL_LAN21` — Netlist and libraries shall not have upper-lower case clash
- `NTL_LAN22` — Do not use escaped names
- `NTL_LAN24` — Do not distinguish names by using upper or lower-case English letters in the same module

## NAM

- `NTL_NAM01` — Use the same name for all clocks that are driven from the same source
- `NTL_NAM02` — Clock ports must be assigned to internal clock signals that start with clk
- `NTL_NAM03` — A reset port must be assigned to an internal reset signal that starts with rst
- `NTL_NAM07` — A registered output port should end with _r
- `NTL_NAM09` — Intentionally latched signals must end with _q
- `NTL_NAM16` — Active low signals must end with "_X, _N"
- `NTL_NAM18` — A signal fed through an inverter or buffer may only have its suffix changed

## PAD

- `NTL_PAD04` — Cell whose PAD pin is not connected to an external signal of the top unit
- `NTL_PAD05` — Controllable pull-up
- `NTL_PAD06` — Controllable pull-down
- `NTL_PAD07` — Push pull always disabled
- `NTL_PAD08` — Input port always disabled
- `NTL_PAD09` — Forbidden PAD connection
- `NTL_PAD10` — Output port always disabled
- `NTL_PAD11` — Isolate I/O PAD from the core logic %s1
- `NTL_PAD13` — Primary inputs of the core must be connected to exactly 1 PAD cell
- `NTL_PAD14` — The PAD terminal of I/O buffer should be connected to primary port only
- `NTL_PAD15` — Primary ports must be connected to PAD cell: %s1

## PAR

- `NTL_PAR12` — Separate flip-flops with asynchronous sets or resets into separate modules
- `NTL_PAR13` — Separate the design according to clock domains
- `NTL_PAR17` — Asynchronous parts should be placed in separate entities
- `NTL_PAR18` — Clock and Reset generators should be located at the top of the design in a dedicated module
- `NTL_PAR19` — Clock generation logic should be put in a particular module: %s1

## RST

- `NTL_RST01` — Use only one reset domain
- `NTL_RST02` — A system reset must be defined
- `NTL_RST03` — All registers must be asynchronously set or reset %s1
- `NTL_RST04` — Reset/Set must not be used as data %s
- `NTL_RST05` — Don't use asynchronous set/reset signal except for initial reset
- `NTL_RST06` — Avoid internally generated resets %s1
- `NTL_RST07` — Don't use one reset signal for both asynchronous reset and synchronous reset
- `NTL_RST08` — Locally gated asynchronous resets should be avoided
- `NTL_RST09` — Reset signal gated with an OR gate
- `NTL_RST10` — Reset signal gated with an AND gate
- `NTL_RST11` — Reset signal gated with another combinatorial cell
- `NTL_RST12` — Buffer on reset path detected
- `NTL_RST13` — Inverter on reset path detected
- `NTL_RST14` — Reset pin not connected to reset net
- `NTL_RST16` — Reconvergent path on reset tree detected
- `NTL_RST17` — Reset gating must take care of the flip-flop triggering edge. Flip-flop must be of opposite edge
- `NTL_RST18` — Reset/Set signal must not interact with the other latch pins
- `NTL_RST19` — Use only one edge of the reset
- `NTL_RST20` — All latches must be asynchronously set or reset: %s
- `NTL_RST21` — Generates clock-to-preset/clear usage matrix for specified clock and preset/clear signals
- `NTL_RST22` — If you internally generate reset signals, do so in a single module instantiated at the top-level of the design
- `NTL_RST23` — Use asynchronous reset for initial reset to register
- `NTL_RST24` — Source and Destination flip-flops use different asynchronous resets.

## SET

- `NTL_SET01` — Use only one set domain
- `NTL_SET02` — Use only one edge of the set
- `NTL_SET03` — Don't use one set signal for both asynchronous set and synchronous set %s
- `NTL_SET04` — Locally gated asynchronous sets should be avoided %s

## STR

- `NTL_STR01` — Use only fully synchronous flip-flops
- `NTL_STR02` — Avoid asynchronous design
- `NTL_STR03` — Input pins should be registered
- `NTL_STR04` — Output enables used by the external output drivers should be registered before leaving the ASIC logic level
- `NTL_STR05` — A signal that passes through several hierarchical levels must have the same name throughout
- `NTL_STR06` — Top-level output should be registered
- `NTL_STR07` — Avoid glue logic at top level
- `NTL_STR08` — The number of gate instantiation should not exceed &lt;NB_MAX_GATES&gt; in instance: %s1
- `NTL_STR09` — Avoid snake paths
- `NTL_STR11` — VDD and GND must not be fed directly into logic
- `NTL_STR12` — Avoid nets that branch out to two different ports of the same module
- `NTL_STR13` — Re-entrant outputs are not allowed (except for bidirectional pins)
- `NTL_STR14` — Check that circuits labeled _meta are really proper metastable circuits
- `NTL_STR15` — Give unique names to synchronizers so that they can be identified
- `NTL_STR16` — Do not use bidirectional ports in submodules of your design
- `NTL_STR18` — Avoid clock as set or reset circuitry
- `NTL_STR19` — Detected multiply-driven signal %s1
- `NTL_STR20` — Each output enable signal should be assigned to no more than MAX_DRIVING_NUMBER primary outputs
- `NTL_STR21` — The level of the design hierarchy should not exceed %d: %s
- `NTL_STR22` — Inhibit use of black box
- `NTL_STR23` — Max number of fanout between modules
- `NTL_STR24` — Number of logical levels between 2 flip-flops exceeds maximum limit
- `NTL_STR26` — No INOUTs at any top level block; although acceptable, they consume a lot of resources in the box
- `NTL_STR27` — Parallel inverters
- `NTL_STR28` — Delay line
- `NTL_STR29` — Pulse generator
- `NTL_STR30` — Shift registers
- `NTL_STR31` — Netlist not uniquified
- `NTL_STR32` — Reconvergent path detected between %s1
- `NTL_STR33` — Asynchronous feedback loop detected
- `NTL_STR34` — No internal three-state buffers are allowed
- `NTL_STR37` — Avoid combinatorial logic on the control signal of a tristate driver
- `NTL_STR43` — Use template for inferred tristate buffer
- `NTL_STR44` — A core tri-state signal must be driven from a separate module %s
- `NTL_STR45` — Single tristate detected
- `NTL_STR47` — Do not use latch
- `NTL_STR48` — Latches shall be instantiated using the VLSI generic latch components
- `NTL_STR50` — Inhibit: Latch to Latch path detected
- `NTL_STR51` — Inhibit: Latch with set &amp; reset
- `NTL_STR52` — Flip-flop not active in test mode
- `NTL_STR53` — Anti-skew latch enable not controlled by main clock
- `NTL_STR54` — The enable signals of tristate or bidirectional ports must be available at the core boundary
- `NTL_STR55` — Do not use bidirectional ports for scan enable
- `NTL_STR56` — Do not use sequential registers with both asynchronous set and asynchronous reset
- `NTL_STR58` — Register controlled by multiple clocks
- `NTL_STR59` — Inout signal connect to register clock
- `NTL_STR61` — Do not use clock or enable signals as data inputs
- `NTL_STR62` — Netlist shall not have parallel drive situations
- `NTL_STR63` — Tristate and non-tristate drivers are driving the same net
- `NTL_STR65` — The number of buffers/inverters should not exceed the user specified percentage of total cell count: %s1
- `NTL_STR66` — Do not instantiate big buffers
- `NTL_STR67` — The maximum number of flip-flops that belong to one clock domain should not exceed %d1:%s The number of flip-flops that belong to this clock domain is %d2:%s
- `NTL_STR68` — Don't use that cell
- `NTL_STR69` — Do not use feedthrough
- `NTL_STR70` — Set and reset signals must not come from a common source
- `NTL_STR71` — Do not use ring oscillator
- `NTL_STR72` — A non-tristate net can have only one non-tristate driver
- `NTL_STR73` — A tristate net shall have exactly 1 bus keeper cell
- `NTL_STR74` — A non-tristate net shall have zero bus keeper
- `NTL_STR75` — Different Vt cells used
- `NTL_STR76` — A non-tristate net can have only one non-tristate driver except in case of parallel driver %s1
- `NTL_STR77` — Prohibit Cell
- `NTL_STR77A` — Prohibited cell found %s
- `NTL_STR78` — Output of latch is connected to self input
- `NTL_STR79` — Redundant logic
- `NTL_STR80` — The total cell area
- `NTL_STR81` — When use FF/LATCH with both set and reset, either set or reset should be connected to fixed value (VDD/GND) %s1. Set pin is %s2. Reset pin is %s1
- `NTL_STR82` — Reset/Set of FF/LATCH should be connected to system reset/set or noise cancel circuit
- `NTL_STR83` — Use only parallel connections that are supported by PrimeTime
- `NTL_STR84` — Latch enabled by a clock feeds latches enabled by the same clock %s1
- `NTL_STR85` — Flip-flops likely to be merged in synthesis
- `NTL_STR86` — No fanout within synchronizer
- `NTL_STR87` — The name and number of all cells (for gate-level designs)
- `NTL_STR88` — The number of ports in modules
- `NTL_STR89` — Signal driven by multiple modules
- `NTL_STR90` — No bus contention on &lt;bus&gt;
- `NTL_STR92` — Detected input DDR flip-flop
- `NTL_STR93` — Detecting ODDR FFs
- `NTL_STR99` — Max area size of each module should be less than 10000
- `NTL_STR100` — When area size of hierarchy is more that 10000, it should not have glue logics
- `NTL_STR110` — A signal without a resolution function cannot have multiple sources driving it

