`include "defines.v"

module bos(
//// main
input fpga_clk_100,   // для периферии и sys clk
input fpga_clk_48,
//input fpga_clk_dac, // clk from dds
//input sbis_power_on,  // flag that sbis is ok

//// RS-485
output  tx,
input   rx,

//// Digital potentiometers
output  dac_din,
output  dac_sclk,
output  dac_sync_n,
input   dac_sdo,
input   dac_rdy,                // indicates completion of read/write
output  dac_rst_n,              // reset resistor value to midscale
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
//output  dds_io_upd,   // ad9952 datasheet page 7
//output  dds_rst,
//output  dds_cs_n,
//inout   dds_sdio,
//output  dds_sclk,

//// other control signals
output reg        dac_gain,             // off/on analog signal attenuation
output reg        dac_switch_out_fpga,  // differential/regular analog signal
output reg        dac_ena_out_fpga,     // disable/enable output of analog signal
output reg [3:0]  a,                    // address on multiplexer to select Q[i]
output reg        load_pr_3v7,          // connects mux output with 1.65 kOhm load
output reg        load_pdr,             // connects mux output with 240 Ohm load
output reg        off_pr_digital_fpga,  // off/on overvoltage to digital inputs of BOS
output reg        off_vcore_fpga,       // off/on v_core
output reg        off_vdigital_fpga,    // off_on v_digital
output reg        functional,           // off/on level translators

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
//output [13:0] dac_d,
//output        dac_clk_ext,    // assign fpga_clk_dac

//// SBIS BOS
//input  [11:0] q_fpga,       // parallel video data from sbis bos
//input         dataclk_fpga,
//
//output        rst_fpga,     // rst of sbis
//output        clk_fpga,     // сюда подать 10 MHz из clk_dds
//output        stby_fpga,    // вход режима простоя
//
//output        shp_fpga,     // вход тактов обработки
//output        hd_fpga,      // вход управления горизонтальной развёрткой
//output        pblk_fpga,    // вход импульса гашения
//output        vd_fpga,      // вход управления вертикальной развёрткой
//output        clpdm_fpga,   // вход импульса привязки на входе
//output        shd_fpga,     // вход тактов уровня данных
//output        clpob_fpga,   // вход импульса привязки на выходе
//
output        sl_fpga,      // SPI control - cs
output        sdatai_fpga,  // SPI control - mosi
input         sdatao_fpga,  // SPI control - miso
output        sck_fpga,     // SPI control - sclk
//
//output        slv_fpga,     // SPI video - cs      
//output        sckv_fpga,    // SPI video - sclk    // 48 MHz
//input         sdatav_fpga   // SPI video - miso

//// DEBUG
input                       n_rst,
output [2:0]                my_state,
output [$clog2(`N_SRC)-1:0] my_current_source,
output [7:0]                my_cnt,
output [7:0]                my_rx_data,
output                      my_rx_valid,
output [7:0]                my_tx_data,
output                      my_tx_valid,
output                      my_tx_ready,
output [1*`N_SRC-1:0]       my_rdreq_bus,
output [7:0]                my_crc,
output [1*`N_SRC-1:0]       my_have_msg_bus,
output [8*`N_SRC-1:0]       my_len_bus
);
assign my_rx_data = rx_data;
assign my_rx_valid = rx_valid;
assign my_tx_data = tx_data;
assign my_tx_valid = tx_valid;
assign my_tx_ready = tx_ready;
assign my_rdreq_bus = rdreq_bus;
assign my_have_msg_bus = have_msg_bus;
assign my_len_bus = len_bus;

       
       
if_spi #(.D_WIDTH(16)) potentiometer_1
(
  .n_rst    (n_rst),
  .clk      (fpga_clk_48),
  .cs       (dac_sync_n),
  .sclk     (dac_sclk),
  .mosi     (dac_din),
  .miso     (dac_sdo),
  .in_data  (master_data),
  .in_ena   (valid_bus[0]),
  .rd_req   (rdreq_bus[0]),
  .out_data (slave_data_bus[8*0+:8]),
  .have_msg (have_msg_bus[0]),
  .len      (len_bus[8*0+:8])
);
assign dac_rst_n = 1'b1; // no hardware reset



if_spi_multi #(.N_SLAVES(3)) potentiometers
(
  .n_rst   (n_rst),
  .clk     (fpga_clk_48),
  .sclk    (sclk_power),
  .mosi    (din_power),
  .miso    (),
  .n_cs_bus({sync_vpr_digital_n, sync_digital_n, sync_core_n}),  
  .m_din   (master_data),
  .m_wrreq (valid_bus[3:1]),
  .s_dout  (slave_data_bus[8*1+:8*3]),
  .len     (len_bus[8*1+:8*3]),
  .have_msg(have_msg_bus[3:1]),
  .s_rdreq (rdreq_bus[3:1])
);
assign rst_power_n = 1'b1;



if_spi #(.D_WIDTH(16)) adc_1
(
  .n_rst    (n_rst),
  .clk      (fpga_clk_48),
  .cs       (adc_cs_pwr_n),
  .sclk     (adc_sclk_pwr),
  .mosi     (adc_din_pwr),
  .miso     (adc_dout_pwr),
  .in_data  (master_data),
  .in_ena   (valid_bus[4]),
  .rd_req   (rdreq_bus[4]),
  .out_data (slave_data_bus[8*4+:8]),
  .have_msg (have_msg_bus[4]),
  .len      (len_bus[8*4+:8])
);



if_spi_multi #(.N_SLAVES(2)) adcs
(
  .n_rst   (n_rst),
  .clk     (fpga_clk_48),
  .sclk    (adc_sclk),
  .mosi    (adc_din),
  .miso    (adc_dout),
  .n_cs_bus({adc2_cs_n, adc1_cs_n}),  
  .m_din   (master_data),
  .m_wrreq (valid_bus[6:5]),
  .s_dout  (slave_data_bus[8*5+:8*2]),
  .len     (len_bus[8*5+:8*2]),
  .have_msg(have_msg_bus[6:5]),
  .s_rdreq (rdreq_bus[6:5])
);



if_spi #(.D_WIDTH(24)) spi_bos
(
  .n_rst    (n_rst),
  .clk      (fpga_clk_48),
  .cs       (sl_fpga),
  .sclk     (sck_fpga),
  .mosi     (sdatai_fpga),
  .miso     (sdatao_fpga),
  .in_data  (master_data),
  .in_ena   (valid_bus[8]),
  .rd_req   (rdreq_bus[8]),
  .out_data (slave_data_bus[8*8+:8]),
  .have_msg (have_msg_bus[8]),
  .len      (len_bus[8*8+:8])
);



cmd_decoder cmd_decoder
(
  .n_rst    (n_rst),
  .clk      (fpga_clk_48),
  .rx_data  (rx_data),
  .rx_valid (rx_valid),
  .rx_ready (rx_ready),
  .q        (master_data),
  .valid_bus(valid_bus)
);
wire [7:0]        master_data;
wire [`N_SRC-1:0] valid_bus;



cmd_encoder cmd_encoder
(
  .n_rst        (n_rst),
  .clk          (fpga_clk_48),
  .have_msg_bus (have_msg_bus),
  .data_bus     (slave_data_bus),
  .len_bus      (len_bus),
  .rdreq_bus    (rdreq_bus),
  .tx_data      (tx_data),
  .tx_valid     (tx_valid),
  .tx_ready     (tx_ready),
  // debug
  .my_state         (my_state),
  .my_current_source(my_current_source),
  .my_cnt           (my_cnt),
  .my_crc           (my_crc)
);
wire [1*`N_SRC-1:0] have_msg_bus;
wire [8*`N_SRC-1:0] slave_data_bus;
wire [8*`N_SRC-1:0] len_bus;
wire [1*`N_SRC-1:0] rdreq_bus;



uart uart
(
  .clk                (fpga_clk_48),
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
  .prescale           (PRESCALE)
);
localparam PRESCALE = 50000000 / (115200 * 8);	// = fclk / (baud * 8)
wire [7:0]  rx_data;
wire        rx_valid;
wire        tx_ready;
wire [7:0]  tx_data;
wire        tx_valid;
wire        rx_ready;



reg video_in_select;    // 0 = parallel, 1 = serial
always@(posedge fpga_clk_48)
  begin
  if(valid_bus[11]) a                   <= master_data[3:0];
  if(valid_bus[12]) begin
                    load_pr_3v7         <= master_data[1];
                    load_pdr            <= master_data[0];
                    end
  if(valid_bus[13]) dac_gain            <= master_data[0];           
  if(valid_bus[14]) dac_switch_out_fpga <= master_data[0];
  if(valid_bus[15]) dac_ena_out_fpga    <= master_data[0];
  if(valid_bus[16]) off_pr_digital_fpga <= master_data[0];
  if(valid_bus[17]) functional          <= master_data[0];
  if(valid_bus[18]) video_in_select     <= master_data[0];
  if(valid_bus[19]) off_vcore_fpga      <= master_data[0];
  if(valid_bus[20]) off_vdigital_fpga   <= master_data[0];

  end


endmodule