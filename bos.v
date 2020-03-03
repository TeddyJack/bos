`include "defines.v"

module bos (
  //// input clocks
  input fpga_clk_100,
//input fpga_clk_48,    // not used so far; assign to PIN_A8 if used
  input fpga_clk_dac,   // clk from dds; not used so far; assign to PIN_R9 if used
  
  //// RS-485
  output  tx,
  input   rx,
  
  //// Digital potentiometers
  output  dac_din,
  output  dac_sclk,
  output  dac_sync_n,
  input   dac_sdo,
  input   dac_rdy,              // indicates completion of read/write
  output  dac_rst_n,            // reset resistor value to midscale
  output  din_power,            // pcb power, D1 D2 D13
  output  sclk_power,           // pcb power, D1 D2 D13
  output  rst_power_n,          // pcb power, D1 D2 D13
  output  sync_core_n,          // pcb power, D1
  output  sync_digital_n,       // pcb power,    D2
  output  sync_vpr_digital_n,   // pcb power,       D13
  
  //// ADCs
  output  adc_sclk_pwr, // D12
  output  adc_din_pwr,  // D12
  input   adc_dout_pwr, // D12
  output  adc_cs_pwr_n, // D12
  output  adc_sclk,     // D13, D14
  output  adc_din,      // D13, D14
  input   adc_dout,     // D13, D14
  output  adc1_cs_n,    // D13
  output  adc2_cs_n,    //      D14
  
  //// DDS
  output  dds_io_upd,   // ad9952 datasheet page 7
  output  dds_rst,
  output  dds_cs_n,
  inout   dds_sdio,
  output  dds_sclk,
  
  //// other control signals
  output        dac_gain,             // off/on analog signal attenuation
  output        dac_switch_out_fpga,  // differential/regular analog signal
  output        dac_ena_out_fpga,     // disable/enable output of analog signal
  output [3:0]  a,                    // address on multiplexer to select Q[i]
  output        load_pr_3v7,          // connects mux output with 1.65 kOhm load
  output        load_pdr,             // connects mux output with 240 Ohm load
  output        off_pr_digital_fpga,  // off/on overvoltage to digital inputs of BOS
  output        off_vcore_fpga,       // off/on v_core
  output        off_vdigital_fpga,    // off_on v_digital
  output        functional,           // off/on level translators
  
  //// RAM
  //output [12:0] sdram_a,
  //output [1:0]  sdram_ba,     // bank address
  //inout  [15:0] sdram_dq,     // data i/o
  //output        sdram_clk,
  //output        sdram_cke,    // clock enable
  //output        sdram_we_n,   // write_enable
  //output        sdram_cas_n,  // column address strobe command
  //output        sdram_ras_n,  // row address strobe command
  //output        sdram_cs_n,   // chip select
  
  //// DAC
  output [13:0] dac_d,
  output        dac_clk_ext,
  
  //// SBIS BOS
  input         sbis_power_on,// flag that sbis is ok
  output        rst_fpga,     // rst of sbis
  output        stby_fpga,    // standby mode of sbis
  //
  output        clk_fpga,     // sampling clock for data
  output        shp_fpga,     // sampling clock for reference level
  output        shd_fpga,     // sampling clock for data level
  output        hd_fpga,      // horiz drive (used for color steering control)
  output        vd_fpga,      // vert drive (used for color steering control)
  output        clpdm_fpga,   // input clamp clock
  output        clpob_fpga,   // black level clamp clock
  output        pblk_fpga,    // pre blanking clock
  //
  output        sl_fpga,      // SPI control - cs
  inout         sdatai_fpga,  // SPI control - sdio
//input         sdatao_fpga,  // SPI control - miso, not used so far; assign to PIN_B7 if used
  output        sck_fpga,     // SPI control - sclk
  //
  input         dataclk_fpga, // delayed clk_fpga
  input  [11:0] q_fpga,       // parallel video data from sbis bos
  //
  output        slv_fpga,     // serial video - cs      
  output        sckv_fpga,    // serial video - sclk
  inout         sdatav_fpga   // serial video - sdio
);


wire sys_clk;

wire [7:0]        master_data;
wire [`N_SRC-1:0] valid_bus;

localparam PRESCALE = `SYS_CLK * 10000 / (1152 * 8);	// = fclk / (baud * 8)
wire [7:0]  rx_data;
wire        rx_valid;
wire        tx_ready;
wire [7:0]  tx_data;
wire        tx_valid;
wire        rx_ready;

wire [1*`N_SRC-1:0] have_msg_bus;
wire [8*`N_SRC-1:0] slave_data_bus;
wire [8*`N_SRC-1:0] len_bus;
wire [1*`N_SRC-1:0] rdreq_bus;

wire video_in_sel;

wire n_rst;
wire sclk_common;
wire sclk_video;

assign dac_clk_ext = /*fpga_clk_dac*/sys_clk;

pll_main pll_main (
  .inclk0 (fpga_clk_100),
  .c0     (sys_clk),
  .c1     (sclk_common),
  .c2     (sclk_video),
  .locked (n_rst)
);


// address 0x00
if_spi #(
  .CPOL(0),
  .CPHA(1),
  .BYTES_PER_FRAME(2)
)
potentiometer_1 (
  .n_rst      (n_rst),
  .sys_clk    (sys_clk),
  .sclk_common(sclk_common),
  .n_cs       (dac_sync_n),
  .sclk       (dac_sclk),
  .mosi       (dac_din),
  .miso       (dac_sdo),
  .in_data    (master_data),
  .in_ena     (valid_bus[0]),
  .enc_rdreq  (rdreq_bus[0]),
  .out_data   (slave_data_bus[8*0+:8]),
  .have_msg   (have_msg_bus[0]),
  .len        (len_bus[8*0+:8])
);

assign dac_rst_n = 1'b1; // no hardware reset


// addresses 0x01-0x03
if_spi_multi #(
  .N_SLAVES(3),
  .CPOL(0),
  .CPHA(1),
  .BYTES_PER_FRAME(2)
)
potentiometers (
  .n_rst       (n_rst),
  .sys_clk     (sys_clk),
  .sclk_common (sclk_common),
  .sclk        (sclk_power),
  .mosi        (din_power),
  .miso        (),
  .n_cs_bus    ({sync_vpr_digital_n, sync_digital_n, sync_core_n}),  
  .m_din       (master_data),
  .m_wrreq_bus (valid_bus[3:1]),
  .s_dout_bus  (slave_data_bus[8*1+:8*3]),
  .len_bus     (len_bus[8*1+:8*3]),
  .have_msg_bus(have_msg_bus[3:1]),
  .s_rdreq_bus (rdreq_bus[3:1])
);

assign rst_power_n = 1'b1;


// address 0x04
if_spi #(
  .CPOL(1),
  .CPHA(1),
  .BYTES_PER_FRAME(2)
)
adc_1 (
  .n_rst      (n_rst),
  .sys_clk    (sys_clk),
  .sclk_common(sclk_common),
  .n_cs       (adc_cs_pwr_n),
  .sclk       (adc_sclk_pwr),
  .mosi       (adc_din_pwr),
  .miso       (adc_dout_pwr),
  .in_data    (master_data),
  .in_ena     (valid_bus[4]),
  .enc_rdreq  (rdreq_bus[4]),
  .out_data   (slave_data_bus[8*4+:8]),
  .have_msg   (have_msg_bus[4]),
  .len        (len_bus[8*4+:8])
);


// addresses 0x05-0x06
if_spi_multi #(
  .N_SLAVES(2),
  .CPOL(1),
  .CPHA(1),
  .BYTES_PER_FRAME(2)
)
adcs (
  .n_rst       (n_rst),
  .sys_clk     (sys_clk),
  .sclk_common (sclk_common),
  .sclk        (adc_sclk),
  .mosi        (adc_din),
  .miso        (adc_dout),
  .n_cs_bus    ({adc2_cs_n, adc1_cs_n}),  
  .m_din       (master_data),
  .m_wrreq_bus (valid_bus[6:5]),
  .s_dout_bus  (slave_data_bus[8*5+:8*2]),
  .len_bus     (len_bus[8*5+:8*2]),
  .have_msg_bus(have_msg_bus[6:5]),
  .s_rdreq_bus (rdreq_bus[6:5])
);


// address 0x07
if_spi #(
  .CPOL(0),
  .CPHA(0),
  .BYTES_PER_FRAME(0),
  .BIDIR(1),
  .SWAP_DIR_BIT_NUM(7)
)
spi_dds (
  .n_rst      (n_rst),
  .sys_clk    (sys_clk),
  .sclk_common(sclk_common),
  .n_cs       (dds_cs_n),
  .sclk       (dds_sclk),
  .sdio       (dds_sdio),
  .io_update  (dds_io_upd),
  .in_data    (master_data),
  .in_ena     (valid_bus[7]),
  .enc_rdreq  (rdreq_bus[7]),
  .out_data   (slave_data_bus[8*7+:8]),
  .have_msg   (have_msg_bus[7]),
  .len        (len_bus[8*7+:8])
);

assign dds_rst = 0;


// address 0x08
if_spi #(
  .CPOL(1),
  .CPHA(0),
  .BYTES_PER_FRAME(3),
  .BIDIR(1),
  .SWAP_DIR_BIT_NUM(8)
)
spi_bos (
  .n_rst      (n_rst),
  .sys_clk    (sys_clk),
  .sclk_common(sclk_common),
  .n_cs       (sl_fpga),
  .sclk       (sck_fpga),
  .sdio       (sdatai_fpga),
  .in_data    (master_data),
  .in_ena     (valid_bus[8]),
  .enc_rdreq  (rdreq_bus[8]),
  .out_data   (slave_data_bus[8*8+:8]),
  .have_msg   (have_msg_bus[8]),
  .len        (len_bus[8*8+:8])
);


// addresses 0x09-0x11
fpga_regs fpga_regs (
  .n_rst              (n_rst),
  .clk                (sys_clk),
  .master_data        (master_data),
  .valid_bus          ({valid_bus[24], valid_bus[17:9]}),
  .rdreq_bus          ({rdreq_bus[24], rdreq_bus[17:9]}),
  .have_msg_bus       ({have_msg_bus[24], have_msg_bus[17:9]}),
  .slave_data_bus     ({slave_data_bus[8*24+:8*1], slave_data_bus[8*9+:8*9]}), // (8 * lowest address) +: (8 * num of addresses)
  .len_bus            ({len_bus[8*24+:8*1], len_bus[8*9+:8*9]}),
  .a                  (a),
  .load_pr_3v7        (load_pr_3v7),
  .load_pdr           (load_pdr),
  .dac_gain           (dac_gain),
  .dac_switch_out_fpga(dac_switch_out_fpga),
  .dac_ena_out_fpga   (dac_ena_out_fpga),
  .off_pr_digital_fpga(off_pr_digital_fpga),
  .functional         (functional),   
  .off_vcore_fpga     (off_vcore_fpga),
  .off_vdigital_fpga  (off_vdigital_fpga),
  .rst_fpga           (rst_fpga),
  .stby_fpga          (stby_fpga)
);


// addresses 0x12-0x15
func_testing func_testing (
  // internal and system
  .n_rst          (n_rst),
  .sys_clk        (sys_clk),
  .dds_clk        (/*fpga_clk_dac*/sys_clk),          // fpga_clk_dac not used so far
  .master_data    (master_data),
  .valid_bus      (valid_bus[22:18]),
  .rdreq_bus      (rdreq_bus[22:18]),
  .have_msg_bus   (have_msg_bus[22:18]),
  .len_bus        (len_bus[8*18+:8*5]),
  .slave_data_bus (slave_data_bus[8*18+:8*5]),
  .video_in_select(video_in_sel),
  // connect with DAC
  .dac_d        (dac_d),
  // SBIS BOS parallel output
  .dataclk_fpga (dataclk_fpga),
  .q_fpga       (video_in),
  // SBIS BOS - signals related with analog video signal
  .clk_fpga     (clk_fpga),
  .shp_fpga     (shp_fpga),
  .shd_fpga     (shd_fpga),
  .hd_fpga      (hd_fpga),
  .vd_fpga      (vd_fpga),
  .clpdm_fpga   (clpdm_fpga),
  .clpob_fpga   (clpob_fpga),
  .pblk_fpga    (pblk_fpga)
);


// address 0x16
keep_alive keep_alive (
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .data     (master_data),
  .ena      (valid_bus[23]),
  .have_msg (have_msg_bus[23]),
  .rdreq    (rdreq_bus[23]),
  .data_out (slave_data_bus[8*23+:8]),
  .len      (len_bus[8*23+:8])
);



cmd_decoder cmd_decoder (
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .rx_data  (rx_data),
  .rx_valid (rx_valid),
  .rx_ready (rx_ready),
  .q        (master_data),
  .valid_bus(valid_bus)
);



cmd_encoder cmd_encoder (
  .n_rst        (n_rst),
  .clk          (sys_clk),
  .have_msg_bus (have_msg_bus),
  .data_bus     (slave_data_bus),
  .len_bus      (len_bus),
  .rdreq_bus    (rdreq_bus),
  .tx_data      (tx_data),
  .tx_valid     (tx_valid),
  .tx_ready     (tx_ready)
);



uart uart (
  .clk                (sys_clk),
  .rst                (!n_rst),
  // AXI input
  .input_axis_tdata   (tx_data),    // I make it
  .input_axis_tvalid  (tx_valid),   // I make it
  .input_axis_tready  (tx_ready),
  // AXI output
  .output_axis_tdata  (rx_data),
  .output_axis_tvalid (rx_valid),
  .output_axis_tready (rx_ready),   // I make it
  // UART interface
  .rxd                (rx),
  .txd                (tx),
  // Configuration
  .prescale           (PRESCALE[15:0])
);



video_spi video_spi (
  .n_rst (n_rst),
  .sclk_full (sclk_video),
  .enable (video_in_sel),
  
  .parall_data (data_video_spi),
  
  .sdatav_fpga (sdatav_fpga),
  .slv_fpga (slv_fpga),
  .sckv_fpga (sckv_fpga)
  
  
);

wire [11:0] data_video_spi;
wire [11:0] video_in = video_in_sel ? data_video_spi : q_fpga;



endmodule