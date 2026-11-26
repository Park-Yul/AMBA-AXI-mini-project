
`timescale 1 ns / 1 ps

module spi_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output wire       o_sclk,
    output wire       o_mosi,
    input  wire       i_miso,
    output wire       o_ss_n,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    // Global Clock & Reset Signal
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    // AW Channel
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    // W Channel
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    // B Channel
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    // AR Channel
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    // R Channel
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);
    // my code begin
    wire [7:0] w_clk_div;
    wire       w_start;
    wire [7:0] w_tx_data;
    wire [7:0] w_rx_data;
    wire       w_busy;
    wire       w_done;
    
    // my code end


    // Instantiation of Axi Bus Interface S00_AXI
    spi_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) U_SPI_V1_0_S00_AXI_inst (
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        // my code begin
        .o_clk_div(w_clk_div),
        .o_start(w_start),
        .o_tx_data(w_tx_data),
        .i_rx_data(w_rx_data),
        .i_busy(w_busy),
        .i_done(w_done),
        // my code end
        // AW Channel
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        // W Channel
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        // B Channel
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        // AR Channel
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        // R Channel
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // Add user logic here
    spi U_SPI(
    .i_clk(s00_axi_aclk),
    .i_rst_n(s00_axi_aresetn),
    // internal signals
    .i_clk_div(w_clk_div),
    .i_start(w_start),
    .i_tx_data(w_tx_data),
    .o_rx_data(w_rx_data),
    .o_busy(w_busy),
    .o_done(w_done),
    // external signals
    .o_sclk(o_sclk),
    .o_mosi(o_mosi),
    .i_miso(i_miso),
    .o_ss_n(o_ss_n)
    );
    // User logic ends

endmodule


// spi
module spi (
    input  wire       i_clk,
    input  wire       i_rst_n,
    // internal signals
    input  wire [7:0] i_clk_div,
    input  wire       i_start,
    input  wire [7:0] i_tx_data,
    output wire [7:0] o_rx_data,
    output wire       o_busy,
    output wire       o_done,
    // external ports
    output wire       o_sclk,
    output wire       o_mosi,
    input  wire       i_miso,
    output wire       o_ss_n
);

    // localparam
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    // wire, reg
    // tick signal
    reg r_half_tick;
    reg [7:0] r_half_tick_cnt;
    // FSM
    reg [1:0] r_state;
    reg r_busy, r_done, r_sclk, r_mosi, r_ss_n;
    reg [7:0] r_tx_shift_reg, r_rx_shift_reg;
    reg [2:0] r_bit_cnt;
    reg r_step;
    reg [7:0] r_rx_data;
    reg [7:0] r_clk_div;

    // CL(assign)
    assign o_rx_data = r_rx_shift_reg;
    assign o_busy = r_busy;
    assign o_done = r_done;
    assign o_sclk = r_sclk;
    assign o_mosi = r_mosi;
    assign o_ss_n = r_ss_n;

    // SL(for r_half_tick, r_half_tick_cnt)
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_half_tick     <= 1'b0;
            r_half_tick_cnt <= 0;
        end else begin
            if (r_state == DATA) begin
                if (r_half_tick_cnt == r_clk_div) begin
                    r_half_tick     <= 1'b1;
                    r_half_tick_cnt <= 0;
                end else begin
                    r_half_tick     <= 1'b0;
                    r_half_tick_cnt <= r_half_tick_cnt + 1;
                end
            end else begin
                r_half_tick     <= 1'b0;
                r_half_tick_cnt <= 0;
            end
        end
    end

    // SL(FSM)
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_state        <= IDLE;
            r_busy         <= 1'b0;
            r_done         <= 1'b0;
            r_sclk         <= 1'b0;
            r_mosi         <= 1'b1;
            r_ss_n         <= 1'b1;
            r_tx_shift_reg <= 0;
            r_rx_shift_reg <= 0;
            r_bit_cnt      <= 0;
            r_step         <= 1'b0;
            r_rx_data      <= 0;
            r_clk_div      <= 0;
        end else begin
            case (r_state)
                IDLE: begin
                    r_busy <= 1'b0;
                    r_done <= 1'b0;
                    r_sclk <= 1'b0;
                    r_mosi <= 1'b1;
                    r_ss_n <= 1'b1;
                    if (i_start) begin
                        r_state        <= START;
                        r_busy         <= 1'b1;
                        r_ss_n         <= 1'b0;
                        r_tx_shift_reg <= i_tx_data;
                        r_bit_cnt      <= 0;
                        r_step         <= 1'b0;
                        r_clk_div      <= i_clk_div;
                    end
                end

                START: begin
                    r_state        <= DATA;
                    r_mosi         <= r_tx_shift_reg[7];
                    r_tx_shift_reg <= {r_tx_shift_reg[6:0], 1'b0};
                end

                DATA: begin
                    if (r_half_tick) begin
                        r_sclk <= ~r_sclk;
                        if (r_step == 1'b0) begin  //
                            r_rx_shift_reg <= {r_rx_shift_reg[6:0], i_miso};
                            r_step         <= 1'b1;
                        end else begin
                            r_step <= 1'b0;
                            if (r_bit_cnt < 7) begin
                                r_mosi         <= r_tx_shift_reg[7];
                                r_tx_shift_reg <= {r_tx_shift_reg[6:0], 1'b0};
                                r_bit_cnt      <= r_bit_cnt + 1;
                            end else begin
                                r_state   <= STOP;
                                r_rx_data <= r_rx_shift_reg;
                                r_bit_cnt <= 0;
                            end
                        end
                    end
                end

                STOP: begin
                    r_state <= IDLE;
                    r_done  <= 1'b1;
                    r_sclk  <= 1'b0;
                    r_mosi  <= 1'b1;
                    r_ss_n  <= 1'b1;
                    r_step  <= 1'b0;
                end

                default: begin
                    r_state <= IDLE;
                end
            endcase
        end
    end
endmodule
