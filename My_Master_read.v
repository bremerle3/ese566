///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Create Date : 9/21/2015
// Created by  : Leo Bremer
// University  : Washington University in St Louis
// Description : AMBA AHB-Lite "Junior" Bus Master
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module My_Master (HREADY,HRESETn,HCLK,HRDATA,WRITE,ADDR,WDATA,HADDR,HWRITE,HWDATA,RDATA); 

	input HRESETn, HCLK, WRITE, HREADY; 
    input [31:0] ADDR, WDATA, HRDATA;
	output reg HWRITE;
    output reg[31:0] RDATA, HADDR, HWDATA; 

    reg[31:0] HADDR_D, HWDATA_D, WDATA_D, WDATA_CLKEDGE, RDATA_D, HRDATA_D; //Store previous values of these inputs and outputs
    reg[2:0] state, next_state, prev_state, prev_state_d;  //State registers
    parameter RESET_STATE=0, READ_STATE=1, WRITE_STATE=2, WAIT_STATE=3;

    //Shifted inputs and ouputs
    always @(posedge HCLK) begin
        if(HRESETn == 1'b0) begin
            HADDR_D <= 32'b0;
            RDATA_D <= 32'b0;
            HRDATA_D <= 32'b0;
            WDATA_D <= WDATA;
            WDATA_CLKEDGE <= 32'b0;
            HADDR <= 32'b0;
        end
        else begin
            HADDR_D <= HADDR;
            RDATA_D <= RDATA;
            HRDATA_D <= HRDATA;
            WDATA_D <= WDATA_CLKEDGE;
            WDATA_CLKEDGE <= WDATA;
            HADDR <= ADDR;
        end
    end

    //State register update
    always @(posedge HCLK) begin
        if(HRESETn == 1'b0) begin
            state <= RESET_STATE;
        end
        else begin
            state <= next_state;
        end
        prev_state <= state;  //Need previous state for read/write or write/read transitions
        prev_state_d <= prev_state;
    end

    //State transitions
    always @(state, WRITE, HREADY) begin
        case (state)
            RESET_STATE:
                if (WRITE == 1'b0) begin
                    next_state <= READ_STATE;
                end
                else if (WRITE == 1'b1) begin
                    next_state <= WRITE_STATE;
                end
            READ_STATE:
                if(WRITE == 1'b0) begin
                    next_state <= READ_STATE;
                end
                else if(WRITE == 1'b1) begin
                    next_state <= WRITE_STATE;
                end
            WRITE_STATE:
                if(WRITE == 1'b0) begin
                    next_state <= READ_STATE;
                end
                else if(WRITE == 1'b1) begin
                    next_state <= WRITE_STATE;
                end
            endcase
        end 

    //State machine outputs
    always @(state, HADDR) begin
        if(state == RESET_STATE) begin
            HWRITE <= 1'b0;
            RDATA  <= 32'b0;
            HWDATA <= 32'b0;
            HWDATA_D <= 32'b0;
        end
        else if (state == READ_STATE) begin //Perform a read.
            HWRITE <= WRITE;
            if(HREADY == 1'b1) begin
                RDATA <= HRDATA;
                //Handle write/read transition
                if(prev_state == WRITE_STATE) begin
                    HWDATA  <= HWDATA_D;
                end
            end
            else if (HREADY == 1'b0) begin
                //RDATA <= RDATA_D;
           end
        end  //End read.
        else if (state == WRITE_STATE) begin //Perform a write.
            HWRITE <= WRITE;
            if(HREADY == 1'b1) begin
                HWDATA <= HWDATA_D;
                HWDATA_D <= WDATA_CLKEDGE;
                RDATA <= 32'hDEADBEEF;
                //Handle read/write transition
                if(prev_state == READ_STATE) begin
                    RDATA <= HRDATA;
                    //RDATA <= 32'hBADDADDD;
                end
                if(prev_state_d == READ_STATE) begin
                    RDATA <= HRDATA;
                end
            end 
            else if(HREADY == 1'b0) begin
                //RDATA <= RDATA_D;
            end
        end //End wrote.
    end

endmodule

