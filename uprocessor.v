/* Implementation of pipelined simplescalar RISC microprocessor design *
 * Params:                                                             *
 *   output [7:0] HEX0,HEX1,HEX2,HEX3                                  *
 *        - Output to 7 segment display on output of computation       * 
 *                                                                     * 
 * 	output  [7:0] LEDR, LEDG                                       *
 *        - Binary output to LED                                       *
 *                                                                     * 
 *    input [5:0] KEY                                                  *
 *        - Increment cycles manually - to debug different stages      *
 *          of pipeline                                                *
 *                                                                     * 
 *    input CLOCK_50                                                   *
 *        -  50MHz clock signal                                        *
 *                                                                     */
module simple_uprocessor (KEY, HEX0, HEX1, HEX2, HEX3, CLOCK_50, LEDR, LEDG);
           output [7:0] HEX0, HEX1, HEX2, HEX3; 
	output  [7:0] LEDR;
	output  [7:0] LEDG;
	input [5:0] KEY;
	input  CLOCK_50;
	reg [15:0] mem[0:127]; // 1024-entry, 16-bit memory
	reg [15:0] mdr;         // 16-bit MDR register
	reg [7:0] pc;             // 8-bit MAR register
	initial pc= 8'd8;        // MAR starts with value 8
	initial mdr=16'd65535;
	
	reg [23:0] cc;           // Condition codes are set if result is negative, zero or positive
	
	reg [15:0] mdridde;       // 16-bit MDR register linking Instruction Fetch & Decode stages
	reg [15:0] mdrdeex;     // 16-bit MDR register linking Decode & Execute stages
	reg [15:0] mdrexmem; // 16-bit MDR register linking Execute & Memory stages
	reg [15:0] mdrmemwb; // 16-bit MDR register linking Memory & WriteBack stages
	
	reg [10:0]nextpc1;
	
	reg [15:0] registers[0:7];  
	reg [15:0] registers1;
	reg flag;             // Indicates if pipeline is stalled
	integer czero=0;
	integer cpos=0;
		
	initial 
	begin 
	cc=4'd0;
	mdridde=16'd0;
	mdr1=16'd0;
	mdrdeex=16'd0;	
	flag =1'd0;
	registers[0] = 8'd0;
	registers[1] = 8'd0; 
	registers[2] = 8'd0;
	registers[3] = 8'd0;
	registers[4] = 8'd0;
	registers[5] = 8'd0; 
	registers[6] = 8'd0;
	registers[7] = 8'd0;
	end
	
	reg [16:0]oper1;
	reg [16:0]oper2;
	reg [16:0]oper3;
	reg [16:0]oper4;
	reg [16:0] result;
	reg [16:0] result1;
	
	/*********************************Instruction Fetch Stage **************************************/
	
		always @(posedge CLOCK_50) 
		// always @(posedge KEY[0])   /* For Debug - Manual increment of cycles */ 
		begin
			mdr = mem[pc];
			/* Check for Data dependency\ Control dependency & Branching scenarios*/
			if((mdr!=16'd0) && 
			(/*Add 1 check*/(mdr[15:12]==4'd1 && mdr[5]==0 && 
				(mdr[8:6]==mdridde[11:9] || mdr[8:6]==mdrdeex[11:9] || mdr[8:6]==mdrexmem[11:9] ||
				mdr[8:6]==mdrmemwb[11:9] || mdr[2:0]==mdridde[11:9] || mdr[2:0]==mdrdeex[11:9] || 
				mdr[2:0]==mdrexmem[11:9] || mdr[2:0]==mdrmemwb[11:9] || mdr[11:9]==mdridde[11:9] || 
				mdr[11:9]==mdrdeex[11:9] || mdr[11:9]==mdrexmem[11:9] || mdr[11:9]==mdrmemwb[11:9])) ||
			/*Add 2 check */(mdr[15:12]==4'd1 && mdr[5]==1 &&
				(mdr[8:6]==mdridde[11:9] ||  mdr[8:6]==mdrdeex[11:9] || mdr[8:6]==mdrexmem[11:9] ||
				mdr[8:6]==mdrmemwb[11:9] || mdr[11:9]==mdridde[11:9] || mdr[11:9]==mdrdeex[11:9] || 
				mdr[11:9]==mdrexmem[11:9] || mdr[11:9]==mdrmemwb[11:9])) ||
			/*LOAD check starts*/ (mdr[15:12]==4'd6 && 
				(((mdr[8:6]==mdridde[11:9] || mdr[11:9]==mdridde[11:9]) && mdridde!=0)        ||
				((mdr[8:6]==mdrdeex[11:9] || mdr[11:9]==mdrdeex[11:9]) && mdrdeex!=0)         || 
				((mdr[8:6]==mdrexmem[11:9] || mdr[11:9]==mdrexmem[11:9]) && mdrexmem!=0)      ||
				((mdr[8:6]==mdrmemwb[11:9] ||   mdr[11:9]==mdrmemwb[11:9]) && mdrmemwb!=0)))  ||
			/*STORE check starts */ (mdr[15:12]==4'd7 && 
				(((mdr[8:6]==mdridde[11:9] || mdr[11:9]==mdridde[11:9]) &&mdridde!=0) ||  
				((mdr[8:6]==mdrdeex[11:9] || mdr[11:9]==mdrdeex[11:9])&&mdrdeex!=0) || 
				((mdr[8:6]==mdrexmem[11:9] || mdr[11:9]==mdrexmem[11:9])&&mdrexmem!=0) ||
				((mdr[8:6]==mdrmemwb[11:9] ||   mdr[11:9]==mdrmemwb[11:9])&&mdrmemwb!=0))))) 
			begin
				/* Stall pipeline if Data or Control or Branch is detected */
				mdridde<=16'd0;
				if (flag==0)
				begin
					if (pc>=126)
					begin 
						pc=126;
					end
					pc=pc;
					flag=1;
				end
			end
			else
			begin
				/* Check for Branching - based on ISA opcodes for BR command */
				if((mdr[15:12]==4'd0) &&((mdr[11]==1'd1) || (mdr[10]==1'd1) || (mdr[9]==1'd1)) && mdr!=16'd0) 
				begin
					flag=0;
					/* If BR command has been decoded - jump to the new PC (offset coming from BR opcode)  */
					if(nextpc1!=10'd0 )
					begin
						/* Checking condition codes & BR opcode based on ISA */
						if( (mdr[11]==1'd1 && cc[2]==1) || (mdr[10]==1 && cc[1]==1) || (mdr[9]==1 && cc[0]==1)) 
						begin
							if (pc+nextpc1>=8'd126)
							begin 
								pc=126;
							end
							else	
							begin					
								pc = pc + nextpc1;
								mdridde<=16'd0;
							end
						end	
					end			
					else
					begin
						mdridde<=mdr;
						pc=pc;
					end
				end
				else
				begin
					/* No Branching - increment the PC to fetch next instruction */
					flag=0;
					if (pc>=126)
					begin 
						pc=126;
					end
					pc= pc+1;
					mdridde<=mdr;  // Update the pipeline register with the instruction
				end	
			end
		end
				
			
	/*********************************Operand Fetch Stage **************************************/
		always @(posedge CLOCK_50) 
		//always @(posedge KEY[0]) /* For Debug - Manual increment of cycles */ 
		begin
			if(mdridde != 16'd0)
			begin
				/* ADD is only command with valid operands */ 
				if(mdridde[15:12]==4'd1)
				begin
					/* Operand1 - converted from binary to decimal */
					oper1<=registers[mdridde[8]*4+mdridde[7]*2+mdridde[6]];
					/* Bit position 5 determines if ADD immediate or ADD with operand2 */
					if(mdridde[5]==0)
					begin
						/* Operand1 - converted from binary to decimal */
						oper2<=registers[mdridde[2]*4+mdridde[1]*2+mdridde[0]];
					end
					else
					begin
						oper2<=$signed(mdridde[4:0]);
					end
				end
			end
			mdrdeex<=mdridde;  // Update the pipeline register with the instruction
		end
	
	/*********************************Execution Stage **************************************/
		always @(posedge CLOCK_50) 
		//always @(posedge KEY[0]) /* For Debug - Manual increment of cycles */ 
		begin
			if(mdrdeex != 16'd0)
			begin
				/* BR Instruction Handling */
				if(mdrdeex[15:12]==4'd0 && mdrdeex!=16'd0)
				begin
					nextpc1=($signed(mdrdeex[8:0])+1);
				end
				else
				begin
					nextpc1 <=10'd0;			
				end
				/* ADD Instruction Handling */
				if(mdrdeex[15:12]==4'd1)
				begin
					oper3=oper1+oper2;
				end
				/* LD Instruction Handling */
				if (mdrdeex[15:12]==4'd6)
				begin
					oper3=registers[mdrdeex[8]*4+mdrdeex[7]*2+mdrdeex[6]]+($signed(mdrdeex[5:0])<<1);
				end
				/* ST Instruction Handling */
				if (mdrdeex[15:12]==4'd7)
				begin
					oper3=registers[mdrdeex[8]*4+mdrdeex[7]*2+mdrdeex[6]]+($signed(mdrdeex[5:0])<<1);
				end
				result<=oper3;
			end
			mdrexmem <= mdrdeex; // Update the pipeline register with the instruction
		end
	
	/*********************************Memory Operation Stage **************************************/
		always @(posedge CLOCK_50)
		//always @(posedge KEY[0]) /* For Debug - Manual increment of cycles */ 
		begin
			if(mdrexmem != 16'd0)
			begin
				/* LD Instruction Handling */
				if (mdrexmem[15:12]==4'd6)
				begin
					/* Load the value from memory */
					oper4=mem[result[15:0]];
					/* Update condition codes based on loaded memory is +ve,-ve or 0 */
					if(oper4[15]==1)
					begin
						cc[2]=1'd1;
						cc[1]=1'd0;
						cc[0]=1'd0;
					end
					if (oper4[15:0]==16'd0)
					begin
						czero=1;
						cc[2]=1'd0;
						cc[1]=1'd1;
						cc[0]=1'd0;
					end
					else 
					begin 
						if (oper4[15]==0 && oper4[15:0]!=16'd0)
						begin
							cc[2]=1'd0;
							cc[1]=1'd0;
							cc[0]=1'd1;
						end
					end
					result1<=oper4;
				end
				/* ST Instruction Handling */
				if (mdrexmem[15:12]==4'd7)
				begin
					/* Store the value into memory */
					mem[result[15:0]]=registers[mdrexmem[11]*4+mdrexmem[10]*2+mdrexmem[9]];
				end
				/* ADD Instruction Handling */
				if (mdrexmem[15:12]==4'd1)
				begin	
					oper4=result;
					/* Update condition codes based on loaded memory is +ve,-ve or 0 */
					if(oper4[15]==1)
					begin
						cc[2]=1'd1;
						cc[1]=1'd0;
						cc[0]=1'd0;
						cpos=0;
						czero=0;
					end
					if (oper4[15:0]==16'd0)
					begin
						czero=1;
						cc[2]=1'd0;
						cc[1]=1'd1;
						cc[0]=1'd0;
					end
					else 
					begin 
						if (oper4[15]==0 && oper4[15:0]!=16'd0)
						begin
							cc[2]=1'd0;
							cc[1]=1'd0;
							cc[0]=1'd1;
						end
					end
					result1<= oper4;
				end
			end
			mdrmemwb <= mdrexmem; // Update the pipeline register with the instruction
		end
	
	/*********************************Write Back Stage **************************************/
		always @(posedge CLOCK_50) 
		//always @(posedge KEY[0])  /* For Debug - Manual increment of cycles */ 
		begin
			if(mdrmemwb !=16'd0)
			begin
				/* LD Instruction Handling */
				if (mdrmemwb [15:12]==4'd6)
				begin
					registers[mdrmemwb [11]*4+mdrmemwb [10]*2+mdrmemwb [9]]<=result1[15:0];
				end
				/* ADD Instruction Handling */
				if(mdrmemwb [15:12]==4'd1)
				begin
					registers[mdrmemwb [11]*4+mdrmemwb [10]*2+mdrmemwb [9]]<=result1[15:0];
				end
			end
		end	
	
	/* Microprocessor pipeline for current cycle is complete at this stage   *
	 * This section outputs the value of registers                           */
	
		//Change this according to which register needs to be displayed.
		assign LEDG[7:0]=registers[5][7:0];     // Register 5 is picked for example.  
		assign LEDR[7:0]=registers[5][15:8];

		/* 7 segment display can output registers */
		SevenSeg sseg0(.IN(registers[1][3:0]),.OUT(HEX0));
		SevenSeg sseg1(.IN(registers[4][3:0]),.OUT(HEX1));
		SevenSeg sseg2(.IN(registers[6][3:0]),.OUT(HEX2));
		SevenSeg sseg3(.IN(registers[7][3:0]),.OUT(HEX3));
		
endmodule







	
	
