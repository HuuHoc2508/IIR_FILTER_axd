module iir_wishbone #(
    parameter DATA_WIDTH = 32,
    parameter COEFF_WIDTH = 32,
    parameter INTERNAL_WIDTH = 64,
    parameter SCALE_SHIFT = 20,
    parameter ADDR_WIDTH = 6
) (
    // Wishbone interface
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o
);

    // Coefficient registers (initialized in reset, no Wishbone write)
    reg signed [COEFF_WIDTH-1:0] b0_s1 = 5509, b1_s1 = 11019, b2_s1 = 5509, a1_s1 = -1998080, a2_s1 = 971584;
    reg signed [COEFF_WIDTH-1:0] b0_s2 = 5180, b1_s2 = 10360, b2_s2 = 5180, a1_s2 = -1878592, a2_s2 = 850752;
    reg signed [COEFF_WIDTH-1:0] b0_s3 = 5007, b1_s3 = 10014, b2_s3 = 5007, a1_s3 = -1815872, a2_s3 = 787328;

    // Input register
    reg signed [DATA_WIDTH-1:0] x_reg;

    // Output wire from iir_top
    wire signed [DATA_WIDTH-1:0] y;

    // Address map
    localparam ADDR_X = 6'h3C;
    localparam ADDR_Y = 6'h40;

    // Instantiate IIR filter
    iir_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .INTERNAL_WIDTH(INTERNAL_WIDTH),
        .SCALE_SHIFT(SCALE_SHIFT)
    ) iir_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .x(x_reg),
        .b0_s1(b0_s1), .b1_s1(b1_s1), .b2_s1(b2_s1), .a1_s1(a1_s1), .a2_s1(a2_s1),
        .b0_s2(b0_s2), .b1_s2(b1_s2), .b2_s2(b2_s2), .a1_s2(a1_s2), .a2_s2(a2_s2),
        .b0_s3(b0_s3), .b1_s3(b1_s3), .b2_s3(b2_s3), .a1_s3(a1_s3), .a2_s3(a2_s3),
        .y(y)
    );

    // Wishbone logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_ack_o <= 0;
            wb_dat_o <= 0;
            x_reg <= 0;
        end else begin
            wb_ack_o <= 0;
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1;
                if (wb_we_i) begin
                    if (wb_adr_i == ADDR_X) begin
                        x_reg <= wb_dat_i;
                    end
                    // Ignore writes to other addresses
                end else begin
                    if (wb_adr_i == ADDR_Y) begin
                        wb_dat_o <= y;
                    end else begin
                        wb_dat_o <= 0; // No other readable registers
                    end
                end
            end
        end
    end

endmodule
