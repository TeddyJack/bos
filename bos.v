`include "defines.v"

module bos(
//// main
//input fpga_clk_100,
input fpga_clk_48,    // used in tb
//input fpga_clk_dac, // clk from dds, disabled for debugging
//input sbis_power_on,  // flag that sbis is ok

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
output  adc_sclk_pwr, // D12  // solder externally
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
output        dac_clk_ext,    // probably should be inverted fpga_clk_dac

//// SBIS BOS
input         dataclk_fpga,
input  [11:0] q_fpga,       // parallel video data from sbis bos
//
//output        rst_fpga,     // rst of sbis
output        clk_fpga,     // sampling clock for sbis
//output        stby_fpga,    // вход режима простоя
//
output        shp_fpga,     // sampling clock for reference level
output        shd_fpga,     // sampling clock for data level
output        hd_fpga,      // horiz drive (used for color steering control)
output        vd_fpga,      // vert drive (used for color steering control)
output        clpdm_fpga,   // input clamp clock
output        clpob_fpga,   // black level clamp clock
output        pblk_fpga,    // pre blanking clock
//
output        sl_fpga,      // SPI control - cs
output        sdatai_fpga,  // SPI control - mosi
input         sdatao_fpga,  // SPI control - miso
output        sck_fpga,     // SPI control - sclk
//
//output        slv_fpga,     // SPI video - cs      
//output        sckv_fpga,    // SPI video - sclk    // 52 MHz
//input         sdatav_fpga,   // SPI video - miso

//// Debug
input         n_rst,
output [7:0]  my_rx_data,
output        my_rx_valid,
output [7:0]  my_master_data,
output [1*`N_SRC-1:0] my_valid_bus,
output [7:0]  my_tx_data,
output        my_tx_valid,
output [1*`N_SRC-1:0] my_have_msg_bus,

output [1:0]  my_state,
output my_m_wrreq,
output [7:0] my_m_used,
output my_m_rdreq,
output [15:0] my_m_q,
output [2:0] my_counter
);


wire sys_clk; assign sys_clk = fpga_clk_48;
wire fpga_clk_dac; assign fpga_clk_dac = sys_clk; // assign for debugging
assign dac_clk_ext = !fpga_clk_dac;

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

//wire n_rst;
//pll_main pll_main
//(
//  .inclk0 (fpga_clk_100),
//  .c0     (sys_clk),
//  .locked ()
//);


// address 0x00
if_spi #(.CPOL(0)) potentiometer_1
(
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .n_cs     (dac_sync_n),
  .sclk     (dac_sclk),
  .mosi     (dac_din),
  .miso     (dac_sdo),
  .in_data  (master_data),
  .in_ena   (valid_bus[0]),
  .enc_rdreq(rdreq_bus[0]),
  .out_data (slave_data_bus[8*0+:8]),
  .have_msg (have_msg_bus[0]),
  .len      (len_bus[8*0+:8])
);
assign dac_rst_n = 1'b1; // no hardware reset


// addresses 0x01-0x03
if_spi_multi #(.N_SLAVES(3), .CPOL(0)) potentiometers
(
  .n_rst       (n_rst),
  .clk         (sys_clk),
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
if_spi #(.CPOL(1)) adc_1
(
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .n_cs     (adc_cs_pwr_n),
  .sclk     (adc_sclk_pwr),
  .mosi     (adc_din_pwr),
  .miso     (adc_dout_pwr),
  .in_data  (master_data),
  .in_ena   (valid_bus[4]),
  .enc_rdreq(rdreq_bus[4]),
  .out_data (slave_data_bus[8*4+:8]),
  .have_msg (have_msg_bus[4]),
  .len      (len_bus[8*4+:8])
);


// addresses 0x05-0x06
if_spi_multi #(.N_SLAVES(2), .CPOL(1)) adcs
(
  .n_rst       (n_rst),
  .clk         (sys_clk),
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
if_spi_9952 spi_dds
(
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .n_cs     (dds_cs_n),
  .sclk     (dds_sclk),
  .sdio     (dds_sdio),
  .io_update(dds_io_upd),
  .in_data  (master_data),
  .in_ena   (valid_bus[7]),
  .enc_rdreq(rdreq_bus[7]),
  .out_data (slave_data_bus[8*7+:8]),
  .have_msg (have_msg_bus[7]),
  .len      (len_bus[8*7+:8])
);
assign dds_rst = 0;


// address 0x08
if_spi #(.CPOL(0)) spi_bos
(
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .n_cs     (sl_fpga),
  .sclk     (sck_fpga),
  .mosi     (sdatai_fpga),
  .miso     (sdatao_fpga),
  .in_data  (master_data),
  .in_ena   (valid_bus[8]),
  .enc_rdreq(rdreq_bus[8]),
  .out_data (slave_data_bus[8*8+:8]),
  .have_msg (have_msg_bus[8]),
  .len      (len_bus[8*8+:8])
);


// addresses 0x09-0x11
fpga_regs fpga_regs
(
  .n_rst              (n_rst),
  .clk                (sys_clk),
  .master_data        (master_data),
  .valid_bus          (valid_bus[17:9]),
  .rdreq_bus          (rdreq_bus[17:9]),
  .have_msg_bus       (have_msg_bus[17:9]),
  .slave_data_bus     (slave_data_bus[8*9+:8*9]), // (8 * lowest address) +: (8 * num of addresses)
  .len_bus            (len_bus[8*9+:8*9]),
  
  .a                  (a),
  .load_pr_3v7        (load_pr_3v7),
  .load_pdr           (load_pdr),
  .dac_gain           (dac_gain),
  .dac_switch_out_fpga(dac_switch_out_fpga),
  .dac_ena_out_fpga   (dac_ena_out_fpga),
  .off_pr_digital_fpga(off_pr_digital_fpga),
  .functional         (functional),   
  .off_vcore_fpga     (off_vcore_fpga),
  .off_vdigital_fpga  (off_vdigital_fpga)
);


// addresses 0x12-0x15
func_testing func_testing
(
  // internal and system
  .n_rst          (n_rst),
  .sys_clk        (sys_clk),
  .dds_clk        (fpga_clk_dac),
  .master_data    (master_data),
  .valid_bus      (valid_bus[21:18]),
  .rdreq_bus      (rdreq_bus[21:18]),
  .have_msg_bus   (have_msg_bus[21:18]),
  .video_in_select(video_in_sel),
  // connect with DAC
  .dac_d        (dac_d),
  // SBIS BOS - signals related with analog video signal
  .clk_fpga     (clk_fpga),
  .shp_fpga     (shp_fpga),
  .shd_fpga     (shd_fpga),
  .hd_fpga      (hd_fpga),
  .vd_fpga      (vd_fpga),
  .clpdm_fpga   (clpdm_fpga),
  .clpob_fpga   (clpob_fpga),
  .pblk_fpga    (pblk_fpga),
  // debug
  .my_state     (my_state),
  .my_m_wrreq   (my_m_wrreq),
  .my_m_used    (my_m_used),
  .my_m_rdreq   (my_m_rdreq),
  .my_m_q       (my_m_q),
  .my_counter   (my_counter)
  
);


// address 0x16
keep_alive keep_alive
(
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .data     (master_data),
  .ena      (valid_bus[22]),
  .have_msg (have_msg_bus[22]),
  .rdreq    (rdreq_bus[22]),
  .data_out (slave_data_bus[8*22+:8]),
  .len      (len_bus[8*22+:8])
);



cmd_decoder cmd_decoder
(
  .n_rst    (n_rst),
  .clk      (sys_clk),
  .rx_data  (rx_data),
  .rx_valid (rx_valid),
  .rx_ready (rx_ready),
  .q        (master_data),
  .valid_bus(valid_bus)
);



cmd_encoder cmd_encoder
(
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



uart uart
(
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


// debug assigns
assign my_rx_data = rx_data;
assign my_rx_valid = rx_valid;
assign my_master_data = master_data;
assign my_valid_bus = valid_bus;
assign my_tx_data = tx_data;
assign my_tx_valid = tx_valid;
assign my_have_msg_bus = have_msg_bus;

endmodule