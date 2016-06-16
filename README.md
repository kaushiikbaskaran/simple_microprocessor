# simple_microprocessor
This project involves implementation of a simple RISC microprocessor capable of handling 4 instructions namely ADD - arithmetic operation, BR - branch instructions, LDW and STW - memory operations. The implementation involves a pipelined simplescalar processor with 5 stages namely: Instruction fetch, Instruction decode and Operand fetch, Execute, Memory and Write-back operations. Pipeline registers are used to transfer the pipeline information between stages and constructed 8 16-bit registers, 16-bit Program counter, 3-bit Conditional register and 256 byte memory. The ISA is fixed length and consists of 16-bit opcodes. 

Pipeline stages: 

1. Instruction fetch:

In this stage, I fetch the instruction from the memory by passing the present Program Counter (PC) value to the memory. From the instruction fetched, both data and control dependency is checked. If any data dependency is detected, such as RAW/WAR/WAW(not possible), the pipeline is stalled by passing the opcode for No Operation (NOP), which I define as 0000h and the program counter value is not incremented. At every cycle, I check if there is any data dependency available, if yes the pipeline is stalled using the above procedure. If a branch instruction is identified, then the pipeline is stalled until all the instructions in the pipeline are retired. Once, this happens the effective address is calculated and the control is transferred to that location by inputting the PC value with the place to be jumped in the instruction fetch stage. Now, the pipeline continues its execution normally. If no dependencies are detected, the PC value is incremented by 1 and in the next clock cycle the subsequent instruction is fetched to be executed. At the end of the pipeline stage, I pass on the crucial details on to the pipeline register "mdridde" to be used by the next stage in the subsequent cycle.

2. Instruction decode and Operand fetch:

This pipeline stage involves effective work only for the addition operation. In the case of add operation, there are 2 possibilities. One option is both the operands are registers and the second option is of the immediate kind wherein one of them is register, while the other is an immediate value. In the former case, both the operands are fetched from the respective register locations and stored in "oper1" and "oper2" pipeline registers. In the latter case, the operand 1 is fetched from the register location and the operand 2 is fetched from the instruction opcode and sign extended before storing to the "oper2" pipeline register. In all the cases of my implementation, I make use of non-blocking assignments. At the end of the pipeline stage, I pass on the crucial details on to the pipeline register "mdrdeex" to be used by the next stage in the subsequent cycle.

3. Execution:

In this pipeline stage, the effective address for the branch instruction is calculated by sign extending the immediate jump value. In the case of add operation, the addition operation is implemented with an ALU and stored in the "result" pipeline register. In the case of the load and store instructions, the address of the memory location to be accessed is obtained by adding the base register with the immediate value. This value too is stored to the "result" pipeline register at the end of the cycle. At the end of the pipeline stage, I pass on the crucial details on to the pipeline register "mdrexmem" to be used by the next stage in the subsequent cycle.

4. Memory:

In this stage, the conditional bits are set if the operation being carried out is either load or addition operation. The conditional bits are set in the register "cc". In the case of the store or load instructions, the memory operation is performed by storing value from a register to the memory location or reading in a value to a register from a memory location respectively. The value read in case of load is stored on to "result1" pipeline register to be used in writeback stage in the next cycle. At the end of the pipeline stage, I pass on the crucial details on to the pipeline register "mdrmemwb" to be used by the next stage in the subsequent cycle.

5. Writeback:
In this stage, the value read or computed is stored on the destination register. This stage can be combined with the second pipeline stage, by having the write happening in the positive edge of the clock and the read happening in the negative edge of the clock.

Approach:

I debugged the pipeline stages using the Hardware entirely and used behavioral modeling i.e. all functionalities are realized in a single module however they can be easily split into separate modules and be controlled by a single main module. I displayed the architectural & pipelined register, PC and cc bit values on the 7-segment display and the LEDs and used Key0 to give an artificial clock effect. Based on the values obtained, I found where the error lies and debugged the code to end up with the desired functionality. At the end, I did the timing analysis and implemented a clock of 50MHz, which handles the delays caused by the circuits effectively well.

Results:

I display the register values on to the 7-segment display and the LEDs for easy verification of the code.

