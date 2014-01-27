-------------------------------------------------------------------------------
-- axi_dma_mm2s_sg_if
-------------------------------------------------------------------------------
--
-- *************************************************************************
--
-- (c) Copyright 2010, 2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:          axi_dma_mm2s_sg_if.vhd
-- Description: This entity is the MM2S Scatter Gather Interface for Descriptor
--              Fetches and Updates.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  axi_dma.vhd
--                   |- axi_dma_pkg.vhd
--                   |- axi_dma_rst_module.vhd
--                   |- axi_dma_reg_module.vhd
--                   |   |- axi_dma_lite_if.vhd
--                   |   |- axi_dma_register.vhd (mm2s)
--                   |   |- axi_dma_register.vhd (s2mm)
--                   |- axi_dma_mm2s_mngr.vhd
--                   |   |- axi_dma_mm2s_sg_if.vhd
--                   |   |- axi_dma_mm2s_sm.vhd
--                   |   |- axi_dma_mm2s_cmdsts_if.vhd
--                   |   |- axi_dma_mm2s_cntrl_strm.vhd
--                   |       |- axi_dma_skid_buf.vhd
--                   |       |- axi_dma_strm_rst.vhd
--                   |- axi_dma_s2mm_mngr.vhd
--                   |   |- axi_dma_s2mm_sg_if.vhd
--                   |   |- axi_dma_s2mm_sm.vhd
--                   |   |- axi_dma_s2mm_cmdsts_if.vhd
--                   |   |- axi_dma_s2mm_sts_strm.vhd
--                   |       |- axi_dma_skid_buf.vhd
--                   |- axi_datamover_v2_00_a.axi_data_mover.vhd (FULL)
--                   |- axi_dma_strm_rst.vhd
--                   |- axi_dma_skid_buf.vhd
--                   |- axi_sg_v3_00_a.axi_sg.vhd
--
-------------------------------------------------------------------------------
-- Author:      Gary Burch
-- History:
--  GAB     3/19/10    v1_00_a
-- ^^^^^^
--  - Initial Release
-- ~~~~~~
--  GAB     6/24/10    v1_00_a
-- ^^^^^^
--  - CR566306 rx Status invalid during halt
-- ~~~~~~
--  GAB     9/03/10    v2_00_a
-- ^^^^^^
--  - Updated libraries to v2_00_a
--  - Updated to support new scatter gather engine update interface
-- ~~~~~~
--  GAB     10/15/10    v3_00_a
-- ^^^^^^
--  - Updated libraries to v3_00_a
-- ~~~~~~
--  GAB     11/15/10    v3_00_a
-- ^^^^^^
--  CR582801
--  Converted all stream paraters ***_DATA_WIDTH to ***_TDATA_WIDTH
-- ~~~~~~
--  GAB     2/15/11     v4_00_a
-- ^^^^^^
--  Updated libraries to v4_00_a
--  CR585409 - Optimized control stream data path by removing resets.  Allows
--             for easier placement and timing closure.
-- ~~~~~~
--  GAB     6/21/11    v5_00_a
-- ^^^^^^
--  Updated to axi_dma_v6_01_a
-- ~~~~~~
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library icap_stream_v1_00_a;
use icap_stream_v1_00_a.axi_dma_pkg.all;


library proc_common_v3_00_a;
use proc_common_v3_00_a.srl_fifo_f;

-------------------------------------------------------------------------------
entity  axi_dma_mm2s_sg_if is
    generic (
        C_PRMRY_IS_ACLK_ASYNC        : integer range 0 to 1          := 0       ;
            -- Primary MM2S/S2MM sync/async mode
            -- 0 = synchronous mode     - all clocks are synchronous
            -- 1 = asynchronous mode    - Any one of the 4 clock inputs is not
            --                            synchronous to the other

        -----------------------------------------------------------------------
        -- Scatter Gather Parameters
        -----------------------------------------------------------------------
        C_SG_INCLUDE_STSCNTRL_STRM      : integer range 0 to 1          := 1    ;
            -- Include or Exclude AXI Status and AXI Control Streams
            -- 0 = Exclude Status and Control Streams
            -- 1 = Include Status and Control Streams

        C_SG_INCLUDE_DESC_QUEUE         : integer range 0 to 1          := 0    ;
            -- Include or Exclude Scatter Gather Descriptor Queuing
            -- 0 = Exclude SG Descriptor Queuing
            -- 1 = Include SG Descriptor Queuing

        C_M_AXIS_SG_TDATA_WIDTH          : integer range 32 to 32        := 32  ;
            -- AXI Master Stream in for descriptor fetch


        C_S_AXIS_UPDPTR_TDATA_WIDTH      : integer range 32 to 32        := 32   ;
            -- 32 Update Status Bits

        C_S_AXIS_UPDSTS_TDATA_WIDTH      : integer range 33 to 33        := 33   ;
            -- 1 IOC bit + 32 Update Status Bits

        C_M_AXI_SG_ADDR_WIDTH           : integer range 32 to 64        := 32   ;
            -- Master AXI Memory Map Data Width for Scatter Gather R/W Port

        C_M_AXI_MM2S_ADDR_WIDTH         : integer range 32 to 64        := 32   ;
            -- Master AXI Memory Map Address Width for MM2S Read Port

        C_M_AXIS_MM2S_CNTRL_TDATA_WIDTH  : integer range 32 to 32        := 32  ;
            -- Master AXI Control Stream Data Width
        C_ENABLE_MULTI_CHANNEL                  : integer range 0 to 1          := 0 ;
        C_FAMILY                        : string                        := "virtex5"
            -- Target FPGA Device Family

    );
    port (

        m_axi_sg_aclk               : in  std_logic                         ;           --
        m_axi_sg_aresetn            : in  std_logic                         ;           --
                                                                                        --
        -- SG MM2S Descriptor Fetch AXI Stream In                                       --
        m_axis_mm2s_ftch_tdata      : in  std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0);           --
        m_axis_mm2s_ftch_tvalid     : in  std_logic                         ;           --
        m_axis_mm2s_ftch_tready     : out std_logic                         ;           --
        m_axis_mm2s_ftch_tlast      : in  std_logic                         ;           --

        m_axis_mm2s_ftch_tdata_new      : in  std_logic_vector                              --
                                        (96 downto 0);           --
        m_axis_mm2s_ftch_tdata_mcdma_new      : in  std_logic_vector                              --
                                        (63 downto 0);           --
        m_axis_mm2s_ftch_tvalid_new     : in  std_logic                         ;           --
        m_axis_ftch1_desc_available     : in std_logic;
                                                                                        --
                                                                                        --
        -- SG MM2S Descriptor Update AXI Stream Out                                     --
        s_axis_mm2s_updtptr_tdata   : out std_logic_vector                              --
                                     (C_S_AXIS_UPDPTR_TDATA_WIDTH-1 downto 0);          --
        s_axis_mm2s_updtptr_tvalid  : out std_logic                         ;           --
        s_axis_mm2s_updtptr_tready  : in  std_logic                         ;           --
        s_axis_mm2s_updtptr_tlast   : out std_logic                         ;           --
                                                                                        --
        s_axis_mm2s_updtsts_tdata   : out std_logic_vector                              --
                                     (C_S_AXIS_UPDSTS_TDATA_WIDTH-1 downto 0);          --
        s_axis_mm2s_updtsts_tvalid  : out std_logic                         ;           --
        s_axis_mm2s_updtsts_tready  : in  std_logic                         ;           --
        s_axis_mm2s_updtsts_tlast   : out std_logic                         ;           --

                                                                                        --
                                                                                        --
        -- MM2S Descriptor Fetch Request (from mm2s_sm)                                 --
        desc_available              : out std_logic                         ;           --
        desc_fetch_req              : in  std_logic                         ;           --
        desc_fetch_done             : out std_logic                         ;           --
        updt_pending                : out std_logic                         ;
        packet_in_progress          : out std_logic                         ;           --
                                                                                        --
        -- MM2S Descriptor Update Request (from mm2s_sm)                                --
        desc_update_done            : out std_logic                         ;           --
                                                                                        --
        mm2s_sts_received_clr       : out std_logic                         ;           --
        mm2s_sts_received           : in  std_logic                         ;           --
        mm2s_ftch_stale_desc        : in  std_logic                         ;           --
        mm2s_done                   : in  std_logic                         ;           --
        mm2s_interr                 : in  std_logic                         ;           --
        mm2s_slverr                 : in  std_logic                         ;           --
        mm2s_decerr                 : in  std_logic                         ;           --
        mm2s_tag                    : in  std_logic_vector(3 downto 0)      ;           --
        mm2s_halt                   : in  std_logic                         ;           --
                                                                                        --
        -- Control Stream Output                                                        --
        cntrlstrm_fifo_wren         : out std_logic                         ;           --
        cntrlstrm_fifo_din          : out std_logic_vector                              --
                                        (C_M_AXIS_MM2S_CNTRL_TDATA_WIDTH downto 0);     --
        cntrlstrm_fifo_full         : in  std_logic                         ;           --
                                                                                        --
                                                                                        --
        -- MM2S Descriptor Field Output                                                 --
        mm2s_new_curdesc            : out std_logic_vector                              --
                                        (C_M_AXI_SG_ADDR_WIDTH-1 downto 0)  ;           --
        mm2s_new_curdesc_wren       : out std_logic                         ;           --
                                                                                        --
        mm2s_desc_baddress          : out std_logic_vector                              --
                                        (C_M_AXI_MM2S_ADDR_WIDTH-1 downto 0);           --
        mm2s_desc_blength           : out std_logic_vector                              --
                                        (BUFFER_LENGTH_WIDTH-1 downto 0)    ;           --
        mm2s_desc_blength_v         : out std_logic_vector                              --
                                        (BUFFER_LENGTH_WIDTH-1 downto 0)    ;           --
        mm2s_desc_blength_s         : out std_logic_vector                              --
                                        (BUFFER_LENGTH_WIDTH-1 downto 0)    ;           --
        mm2s_desc_eof               : out std_logic                         ;           --
        mm2s_desc_sof               : out std_logic                         ;           --
        mm2s_desc_cmplt             : out std_logic                         ;           --
        mm2s_desc_info              : out std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0) ;          --
        mm2s_desc_app0              : out std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0) ;          --
        mm2s_desc_app1              : out std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0) ;          --
        mm2s_desc_app2              : out std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0) ;          --
        mm2s_desc_app3              : out std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0) ;          --
        mm2s_desc_app4              : out std_logic_vector                              --
                                        (C_M_AXIS_SG_TDATA_WIDTH-1 downto 0)            --
    );

end axi_dma_mm2s_sg_if;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of axi_dma_mm2s_sg_if is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- No Functions Declared

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
-- Status reserved bits
constant RESERVED_STS           : std_logic_vector(4 downto 0) := (others => '0');

-- Used to determine when Control word is coming, in order to check SOF bit.
-- This then indicates that the app fields need to be directed towards the
-- control stream fifo.
-- Word Five Count
-- Incrementing these counts by 2 as i am now sending two extra fields from BD
--constant SEVEN_COUNT             : std_logic_vector(3 downto 0) := "1011"; --"0111";
constant SEVEN_COUNT             : std_logic_vector(3 downto 0) := "0001";
-- Word Six Count
--constant EIGHT_COUNT              : std_logic_vector(3 downto 0) := "0101"; --"1000";
constant EIGHT_COUNT              : std_logic_vector(3 downto 0) := "0010";
-- Word Seven Count
--constant NINE_COUNT            : std_logic_vector(3 downto 0) := "1010"; --"1001";
constant NINE_COUNT            : std_logic_vector(3 downto 0) := "0011";

-------------------------------------------------------------------------------
-- Signal / Type Declarations
-------------------------------------------------------------------------------
signal ftch_shftenbl            : std_logic := '0';
signal ftch_tready              : std_logic := '0';
signal desc_fetch_done_i        : std_logic := '0';

signal desc_reg12               : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg11               : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg10               : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg9                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg8                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg7                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg6                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg5                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg4                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg3                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg2                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg1                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_reg0                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_dummy                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal desc_dummy1                : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');

signal mm2s_desc_curdesc_lsb    : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal mm2s_desc_curdesc_msb    : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal mm2s_desc_baddr_lsb      : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal mm2s_desc_baddr_msb      : std_logic_vector(C_M_AXIS_SG_TDATA_WIDTH - 1 downto 0) := (others => '0');
signal mm2s_desc_blength_i      : std_logic_vector(BUFFER_LENGTH_WIDTH - 1 downto 0)    := (others => '0');
signal mm2s_desc_blength_v_i      : std_logic_vector(BUFFER_LENGTH_WIDTH - 1 downto 0)    := (others => '0');
signal mm2s_desc_blength_s_i      : std_logic_vector(BUFFER_LENGTH_WIDTH - 1 downto 0)    := (others => '0');

-- Fetch control signals for driving out control app stream
signal desc_word                : std_logic_vector(3 downto 0) := (others => '0');
signal analyze_control          : std_logic := '0';
signal redirect_app             : std_logic := '0';
signal redirect_app_d1          : std_logic := '0';
signal redirect_app_re          : std_logic := '0';
signal redirect_app_hold        : std_logic := '0';
signal mask_fifo_write          : std_logic := '0';

-- Current descriptor control and fetch throttle control
signal mm2s_new_curdesc_wren_i  : std_logic := '0';
signal mm2s_pending_update      : std_logic := '0';
signal mm2s_pending_ptr_updt    : std_logic := '0';

-- Descriptor Update Signals
signal mm2s_complete            : std_logic := '0';
signal mm2s_xferd_bytes         : std_logic_vector(BUFFER_LENGTH_WIDTH-1 downto 0)      := (others => '0');

-- Update Descriptor Pointer Holding Registers
signal updt_desc_reg0           : std_logic_vector(C_S_AXIS_UPDPTR_TDATA_WIDTH downto 0) := (others => '0');
signal updt_desc_reg1           : std_logic_vector(C_S_AXIS_UPDPTR_TDATA_WIDTH downto 0) := (others => '0');
-- Update Descriptor Status Holding Register
signal updt_desc_reg2           : std_logic_vector(C_S_AXIS_UPDSTS_TDATA_WIDTH downto 0) := (others => '0');

-- Pointer shift control
signal updt_shftenbl            : std_logic := '0';

-- Update pointer stream
signal updtptr_tvalid           : std_logic := '0';
signal updtptr_tlast            : std_logic := '0';
signal updtptr_tdata            : std_logic_vector(C_S_AXIS_UPDPTR_TDATA_WIDTH-1 downto 0) := (others => '0');

-- Update status stream
signal updtsts_tvalid           : std_logic := '0';
signal updtsts_tlast            : std_logic := '0';
signal updtsts_tdata            : std_logic_vector(C_S_AXIS_UPDSTS_TDATA_WIDTH-1 downto 0) := (others => '0');

-- Status control
signal sts_received             : std_logic := '0';
signal sts_received_d1          : std_logic := '0';
signal sts_received_re          : std_logic := '0';

-- Queued Update signals
signal updt_data_clr            : std_logic := '0';
signal updt_sts_clr             : std_logic := '0';
signal updt_data                : std_logic := '0';
signal updt_sts                 : std_logic := '0';

signal packet_start             : std_logic := '0';
signal packet_end               : std_logic := '0';

signal mm2s_halt_d1             : std_logic := '0';
signal mm2s_halt_d2             : std_logic := '0';

signal temp                     : std_logic := '0';
signal m_axis_mm2s_ftch_tlast_new : std_logic := '1';
-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
-- Drive buffer length out
mm2s_desc_blength <= mm2s_desc_blength_i;
mm2s_desc_blength_v <= mm2s_desc_blength_v_i;
mm2s_desc_blength_s <= mm2s_desc_blength_s_i;


-- Drive fetch request done on tlast
--desc_fetch_done_i   <= m_axis_mm2s_ftch_tlast
--                 and m_axis_mm2s_ftch_tvalid
--                 and ftch_tready;

desc_fetch_done_i   <= m_axis_mm2s_ftch_tlast_new
                 and m_axis_mm2s_ftch_tvalid_new;
           ----      and ftch_tready;

-- pass out of module
desc_fetch_done <= desc_fetch_done_i;


-- Shift in data from SG engine if tvalid and fetch request
ftch_shftenbl     <= m_axis_mm2s_ftch_tvalid_new
                        and ftch_tready
                        and desc_fetch_req
                        and not mm2s_pending_update;
--ftch_shftenbl     <= m_axis_mm2s_ftch_tvalid
--                        and ftch_tready
--                        and desc_fetch_req
--                        and not mm2s_pending_update;

-- Passed curdes write out to register module
mm2s_new_curdesc_wren   <= desc_fetch_done_i; --mm2s_new_curdesc_wren_i;

-- tvalid asserted means descriptor availble
desc_available          <= m_axis_ftch1_desc_available; --m_axis_mm2s_ftch_tvalid_new;


--***************************************************************************--
--** Register DataMover Halt to secondary if needed
--***************************************************************************--
GEN_FOR_ASYNC : if C_PRMRY_IS_ACLK_ASYNC = 1 generate
begin
    -- Double register to secondary clock domain.  This is sufficient
    -- because halt will remain asserted until halt_cmplt detected in
    -- reset module in secondary clock domain.
    REG_TO_SECONDARY : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0')then
                    mm2s_halt_d1 <= '0';
                    mm2s_halt_d2 <= '0';
                else
                    mm2s_halt_d1 <= mm2s_halt;
                    mm2s_halt_d2 <= mm2s_halt_d1;
                end if;
            end if;
        end process REG_TO_SECONDARY;

end generate GEN_FOR_ASYNC;

GEN_FOR_SYNC : if C_PRMRY_IS_ACLK_ASYNC = 0 generate
begin
    -- No clock crossing required therefore simple pass through
    mm2s_halt_d2 <= mm2s_halt;

end generate GEN_FOR_SYNC;




--***************************************************************************--
--**                        Descriptor Fetch Logic                         **--
--***************************************************************************--

packet_start <= '1' when mm2s_new_curdesc_wren_i ='1'
                     and desc_reg6(DESC_SOF_BIT) = '1'
           else '0';

packet_end <= '1' when mm2s_new_curdesc_wren_i ='1'
                   and desc_reg6(DESC_EOF_BIT) = '1'
           else '0';

REG_PACKET_PROGRESS : process(m_axi_sg_aclk)
    begin
        if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
            if(m_axi_sg_aresetn = '0' or packet_end = '1')then
                packet_in_progress <= '0';
            elsif(packet_start = '1')then
                packet_in_progress <= '1';
            end if;
        end if;
    end process REG_PACKET_PROGRESS;


-- Status/Control stream enabled therefore APP fields are included
GEN_FTCHIF_WITH_APP : if (C_SG_INCLUDE_STSCNTRL_STRM = 1 and C_ENABLE_MULTI_CHANNEL = 0) generate
-- Control Stream Ethernet TAG
constant ETHERNET_CNTRL_TAG     : std_logic_vector
                                    (C_M_AXIS_MM2S_CNTRL_TDATA_WIDTH - 1 downto 0)
                                    := X"A000_0000";
begin

                        --    desc_reg7     <= m_axis_mm2s_ftch_tdata_new (95 downto 64);
                        --    desc_reg6     <= m_axis_mm2s_ftch_tdata_new (63 downto 32);
                        --    desc_reg2     <= m_axis_mm2s_ftch_tdata_new (31 downto 0);
                        --    desc_reg0     <= m_axis_mm2s_ftch_tdata_new (127 downto 96);

                            desc_reg7 (DESC_STS_CMPLTD_BIT)     <= m_axis_mm2s_ftch_tdata_new (64); -- downto 64);
                            desc_reg6     <= m_axis_mm2s_ftch_tdata_new (63 downto 32);
                            desc_reg2     <= m_axis_mm2s_ftch_tdata_new (31 downto 0);
                            desc_reg0     <= m_axis_mm2s_ftch_tdata_new (96 downto 65);



--       CASE_CNTRL : process(m_axi_sg_aclk)
--        begin
--            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
--                if(m_axi_sg_aresetn = '0')then
--                    desc_reg7     <= (others => '0');
--                    desc_reg6     <= (others => '0');
--                    desc_reg5     <= (others => '0');
--                    desc_reg4     <= (others => '0');
--                --    desc_reg3     <= (others => '0');
--                    desc_reg2     <= (others => '0');
--                --    desc_reg1     <= (others => '0');
--                    desc_reg0     <= (others => '0');
-- 
--                else --if(ftch_shftenbl = '1')then
--                    case desc_word is
--                        when "0000" =>
--                            desc_reg0     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0001"  =>
--                    --        desc_reg1     <= m_axis_mm2s_ftch_tdata;
--                            desc_reg2     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0010" =>
--                          --  desc_reg2     <= m_axis_mm2s_ftch_tdata;
--                            desc_reg6     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0011"  =>
--                         --   desc_reg3     <= m_axis_mm2s_ftch_tdata;
--                            desc_reg7     <= m_axis_mm2s_ftch_tdata;
--                            
----                        when "0100" =>
----                            desc_reg4     <= m_axis_mm2s_ftch_tdata;
--                            
----                        when "0101"  =>
----                            desc_reg5     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0110" =>
--                         --   desc_reg6     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0111"  =>
--                         --   desc_reg7     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1010" =>
--                --            desc_reg8     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1011"  =>
--                --            desc_reg9     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1100" =>
--                --            desc_reg10     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1101"  =>
--                --            desc_reg11     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1110"  =>
--                --            desc_reg12     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when others =>
--                          
--                    end case;
--                end if;
--            end if;
--        end process CASE_CNTRL;
--




    mm2s_desc_curdesc_lsb   <= desc_reg0;
    mm2s_desc_curdesc_msb   <= (others => '0'); --desc_reg1;
    mm2s_desc_baddr_lsb     <= desc_reg2;
    mm2s_desc_baddr_msb     <= (others => '0'); --desc_reg3;
    -- desc 5 are reserved and thus don't care
    -- CR 583779, need to pass on tuser and cache information
    mm2s_desc_info          <= (others => '0'); --desc_reg4; -- this coincides with desc_fetch_done
    mm2s_desc_blength_i     <= desc_reg6(DESC_BLENGTH_MSB_BIT downto DESC_BLENGTH_LSB_BIT);
    mm2s_desc_blength_v_i     <= (others => '0');
    mm2s_desc_blength_s_i     <= (others => '0');
    mm2s_desc_eof           <= desc_reg6(DESC_EOF_BIT);
    mm2s_desc_sof           <= desc_reg6(DESC_SOF_BIT);
    mm2s_desc_cmplt         <= desc_reg7(DESC_STS_CMPLTD_BIT);
    mm2s_desc_app0          <= desc_reg8;
    mm2s_desc_app1          <= desc_reg9;
    mm2s_desc_app2          <= desc_reg10;
    mm2s_desc_app3          <= desc_reg11;
    mm2s_desc_app4          <= desc_reg12;


    -- Drive ready if descriptor fetch request is being made
    -- If not redirecting app fields then drive ready based on sm request
    -- If redirecting app fields then drive ready based on room in cntrl strm fifo

    ftch_tready     <= desc_fetch_req               -- desc fetch request
                   and not mm2s_pending_update; -- no pntr updates pending


--    ftch_tready     <=   '1' when(redirect_app = '0'                -- Not re-directing app fields
--                                and desc_fetch_req = '1'            -- Descriptor fetch requested
--                                and mm2s_pending_update = '0')      -- No pending pointer updates

--                             or (redirect_app = '1'                 -- Re-Directing app fields
--                                and cntrlstrm_fifo_full = '0')      -- control fifo not full
--                                else '0';

    m_axis_mm2s_ftch_tready <= ftch_tready;


    ---------------------------------------------------------------------------
    -- Word Counter for determining which descriptor word is the control word
    ---------------------------------------------------------------------------
    WRD_COUNTER : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0' or desc_fetch_done_i = '1')then
                    desc_word <= (others => '0');
                elsif(ftch_shftenbl = '1')then
                    desc_word <= std_logic_vector(unsigned(desc_word) + 1);
                end if;
             end if;
         end process WRD_COUNTER;

    ---------------------------------------------------------------------------
    -- On correct word count sample stream in to capture control word.  Used
    -- to see if SOF = 1 in order to steer app fields to control stream out.
    ---------------------------------------------------------------------------
--    ANLYZ_CNTRL : process(m_axi_sg_aclk)
--        begin
--            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
--                if(m_axi_sg_aresetn = '0')then
--                    analyze_control <= '0';
--                elsif(m_axis_mm2s_ftch_tvalid = '1')then
--                    case desc_word is
--                        when SEVEN_COUNT =>
--                            analyze_control <= '1';
--                        when EIGHT_COUNT  =>
--                            analyze_control <= '0';
--                        when others =>
--                            analyze_control <= '0';
--                    end case;
--                end if;
--            end if;
--        end process ANLYZ_CNTRL;
--
--    ---------------------------------------------------------------------------
--    -- Flag for directing app fields to control fifo on SOF descriptor
    ---------------------------------------------------------------------------
--    REDIRECT_APP_PROCESS : process(m_axi_sg_aclk)
--        begin
--            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
--                -- Reset or descriptor was stale (i.e. cmplt bit already set)
--                -- therefore do not re-direct app fields
--                if(m_axi_sg_aresetn = '0' or mm2s_ftch_stale_desc = '1')then
--                    redirect_app <= '0';
--                -- Reset flag on fetch complete
--                elsif(desc_fetch_done_i = '1')then
--                    redirect_app <= '0';
--                -- If SOF then redirect to control fifo
--                elsif(analyze_control = '1' and m_axis_mm2s_ftch_tdata(DESC_SOF_BIT) = '1'
--                and m_axis_mm2s_ftch_tvalid = '1')then
--                    redirect_app <= '1';
--                 end if;
--            end if;
--        end process REDIRECT_APP_PROCESS;
--
--
--

                    redirect_app <= '0';
    -- Mux between writing the Ethernet TAG and writing the descriptor APP fields
--    CNTRL_STRM_MUX : process(redirect_app,
--                             mm2s_ftch_stale_desc,
--                             desc_word,
--                             cntrlstrm_fifo_full,
--                             m_axis_mm2s_ftch_tlast_new,
--                             m_axis_mm2s_ftch_tdata,
--                             m_axis_mm2s_ftch_tvalid
--                             )
--        begin
--            -- Write TAG during descriptor status coming in if not
--            -- stale descriptor
--            if(redirect_app = '1' and desc_word = NINE_COUNT
--            and m_axis_mm2s_ftch_tvalid = '1'
--            and m_axis_mm2s_ftch_tdata(DESC_STS_CMPLTD_BIT) = '0')then
--
--                cntrlstrm_fifo_din  <= '0' & ETHERNET_CNTRL_TAG;
--                cntrlstrm_fifo_wren <= not cntrlstrm_fifo_full;
--
--            -- If not on status word (word seven) and not
--            -- a stale descriptor and command to redirect app fields
--            -- then direct app words to control stream fifo
--            elsif(redirect_app='1' and desc_word > NINE_COUNT
--            and m_axis_mm2s_ftch_tvalid = '1'
--            and mm2s_ftch_stale_desc = '0')then
--                cntrlstrm_fifo_din  <= m_axis_mm2s_ftch_tlast_new & m_axis_mm2s_ftch_tdata;
--                cntrlstrm_fifo_wren <= not cntrlstrm_fifo_full;
--            else
--                cntrlstrm_fifo_din  <= (others => '0');
--                cntrlstrm_fifo_wren <= '0';
--            end if;
--        end process CNTRL_STRM_MUX;


end generate GEN_FTCHIF_WITH_APP;


-- Status/Control stream diabled therefore APP fields are NOT included
GEN_FTCHIF_WITHOUT_APP : if C_SG_INCLUDE_STSCNTRL_STRM = 0 generate




    WRD_COUNTER : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0' or desc_fetch_done_i = '1')then
                    desc_word <= (others => '0');
                elsif(ftch_shftenbl = '1')then
                    desc_word <= std_logic_vector(unsigned(desc_word) + 1);
                end if;
             end if;
         end process WRD_COUNTER;



GEN_NO_MCDMA : if C_ENABLE_MULTI_CHANNEL = 0 generate


                            desc_reg7(DESC_STS_CMPLTD_BIT)     <= m_axis_mm2s_ftch_tdata_new (64); --95 downto 64);
                            desc_reg6     <= m_axis_mm2s_ftch_tdata_new (63 downto 32);
                            desc_reg2     <= m_axis_mm2s_ftch_tdata_new (31 downto 0);
                            desc_reg0     <= m_axis_mm2s_ftch_tdata_new (96 downto 65); --127 downto 96);

--       CASE_CNTRL : process(m_axi_sg_aclk)
--        begin
--            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
--                if(m_axi_sg_aresetn = '0')then
-----                    desc_reg7     <= (others => '0');
-----                    desc_reg6     <= (others => '0');
-----                    desc_reg5     <= (others => '0');
-----                    desc_reg4     <= (others => '0');
--                 --   desc_reg3     <= (others => '0');
-----                    desc_reg2     <= (others => '0');
--                 --   desc_reg1     <= (others => '0');
-----                    desc_reg0     <= (others => '0');
-- 
--                else --if(ftch_shftenbl = '1')then
--                    case desc_word is
--                        when "0000" =>
-----                            desc_reg0     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0001"  =>
--                  --          desc_reg1     <= m_axis_mm2s_ftch_tdata;
-----                            desc_reg2     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0010" =>
-----                            desc_reg6     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0011"  =>
--                        --    desc_reg3     <= m_axis_mm2s_ftch_tdata;
-----                            desc_reg7     <= m_axis_mm2s_ftch_tdata;
--                            
--                  --      when "0110" =>
--                  --          desc_reg4     <= m_axis_mm2s_ftch_tdata;
--                            
--                  --      when "0111"  =>
--                  --          desc_reg5     <= m_axis_mm2s_ftch_tdata;
--                            
--                  --      when "1000" =>
--                  --          desc_reg6     <= m_axis_mm2s_ftch_tdata;
--                            
--                  --      when "1001"  =>
----                  --          desc_reg7     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1010" =>
--                --            desc_reg8     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1011"  =>
--              --            desc_reg9     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1100" =>
--              --            desc_reg10     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1101"  =>
--              --            desc_reg11     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1110"  =>
--              --            desc_reg12     <= m_axis_mm2s_ftch_tdata;
--                          
--                        when others =>
--                          
--                    end case;
--                end if;
--            end if;
--        end process CASE_CNTRL;
--



    mm2s_desc_curdesc_lsb   <= desc_reg0;
    mm2s_desc_curdesc_msb   <= (others => '0'); --desc_reg1;
    mm2s_desc_baddr_lsb     <= desc_reg2;
    mm2s_desc_baddr_msb     <= (others => '0'); --desc_reg3;
    -- desc 4 and desc 5 are reserved and thus don't care
    -- CR 583779, need to send the user and xchache info
    mm2s_desc_info          <= (others => '0'); --desc_reg4;
    mm2s_desc_blength_i     <= desc_reg6(DESC_BLENGTH_MSB_BIT downto DESC_BLENGTH_LSB_BIT);
    mm2s_desc_blength_v_i     <= (others => '0');
    mm2s_desc_blength_s_i     <= (others => '0');
    mm2s_desc_eof           <= desc_reg6(DESC_EOF_BIT);
    mm2s_desc_sof           <= desc_reg6(DESC_SOF_BIT);
    mm2s_desc_cmplt         <= desc_reg7(DESC_STS_CMPLTD_BIT);
    mm2s_desc_app0          <= (others => '0');
    mm2s_desc_app1          <= (others => '0');
    mm2s_desc_app2          <= (others => '0');
    mm2s_desc_app3          <= (others => '0');
    mm2s_desc_app4          <= (others => '0');
end generate GEN_NO_MCDMA;


GEN_MCDMA : if C_ENABLE_MULTI_CHANNEL = 1 generate


--       CASE_CNTRL : process(m_axi_sg_aclk)
--        begin
--            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
--                if(m_axi_sg_aresetn = '0')then
--                    desc_reg7     <= (others => '0');
--                    desc_reg6     <= (others => '0');
--                    desc_reg5     <= (others => '0');
--                    desc_reg4     <= (others => '0');
--                    desc_reg3     <= (others => '0');
--                    desc_reg2     <= (others => '0');
--                    desc_reg1     <= (others => '0');
--                    desc_reg0     <= (others => '0');
-- 
--                else --if(ftch_shftenbl = '1')then
--                    case desc_word is
--                        when "0000" =>
--                            desc_reg0     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0001"  =>
--                    --        desc_reg1     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0011" =>
--                            desc_reg2     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0100"  =>
--                    --        desc_reg3     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0101" =>
--                            desc_reg4     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0110"  =>
--                            desc_reg5     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "0111" =>
--                            desc_reg6     <= m_axis_mm2s_ftch_tdata;
--                            
--                        when "1000"  =>
--                            desc_reg7     <= m_axis_mm2s_ftch_tdata;
--                            
--                --        when "1010" =>
--                --            desc_reg8     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1011"  =>
--              --            desc_reg9     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1100" =>
--              --            desc_reg10     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1101"  =>
--              --            desc_reg11     <= m_axis_mm2s_ftch_tdata;
--                          
--              --        when "1110"  =>
--              --            desc_reg12     <= m_axis_mm2s_ftch_tdata;
--                          
--                        when others =>
--                          
--                    end case;
--                end if;
--            end if;
--        end process CASE_CNTRL;


                            desc_reg7 (DESC_STS_CMPLTD_BIT)     <= m_axis_mm2s_ftch_tdata_new (64); --95 downto 64);
                            desc_reg6     <= m_axis_mm2s_ftch_tdata_new (63 downto 32);
                            desc_reg2     <= m_axis_mm2s_ftch_tdata_new (31 downto 0);
                            desc_reg0     <= m_axis_mm2s_ftch_tdata_new (96 downto 65); --127 downto 96);

                            desc_reg4     <= m_axis_mm2s_ftch_tdata_mcdma_new (31 downto 0); --63 downto 32);
                            desc_reg5     <= m_axis_mm2s_ftch_tdata_mcdma_new (63 downto 32);


    mm2s_desc_curdesc_lsb   <= desc_reg0;
    mm2s_desc_curdesc_msb   <= (others => '0'); --desc_reg1;
    mm2s_desc_baddr_lsb     <= desc_reg2;
    mm2s_desc_baddr_msb     <= (others => '0'); --desc_reg3;
-- As per new MCDMA descriptor
    mm2s_desc_info          <= desc_reg4; -- (31 downto 24) & desc_reg7 (23 downto 0);
    mm2s_desc_blength_s_i   <= "0000000" & desc_reg5(15 downto 0); --desc_reg4(DESC_BLENGTH_MSB_BIT downto DESC_BLENGTH_LSB_BIT);
    mm2s_desc_blength_v_i   <= "0000000000" & desc_reg5(31 downto 19); --desc_reg5(DESC_BLENGTH_MSB_BIT downto DESC_BLENGTH_LSB_BIT);
    mm2s_desc_blength_i     <= "0000000" & desc_reg6(15 downto 0); --desc_reg6(DESC_BLENGTH_MSB_BIT downto DESC_BLENGTH_LSB_BIT);
    mm2s_desc_eof           <= desc_reg6(DESC_EOF_BIT);
    mm2s_desc_sof           <= desc_reg6(DESC_SOF_BIT);
    mm2s_desc_cmplt         <= '0' ; --desc_reg7(DESC_STS_CMPLTD_BIT); -- we are not considering the completed bit
    mm2s_desc_app0          <= (others => '0');
    mm2s_desc_app1          <= (others => '0');
    mm2s_desc_app2          <= (others => '0');
    mm2s_desc_app3          <= (others => '0');
    mm2s_desc_app4          <= (others => '0');
end generate GEN_MCDMA;

    -- Drive ready if descriptor fetch request is being made
    ftch_tready     <= desc_fetch_req               -- desc fetch request
                   and not mm2s_pending_update; -- no pntr updates pending


    m_axis_mm2s_ftch_tready <= ftch_tready;

    cntrlstrm_fifo_wren     <= '0';
    cntrlstrm_fifo_din      <= (others => '0');


end generate GEN_FTCHIF_WITHOUT_APP;

-------------------------------------------------------------------------------
-- BUFFER ADDRESS
-------------------------------------------------------------------------------
-- If 64 bit addressing then concatinate msb to lsb
GEN_NEW_64BIT_BUFADDR : if C_M_AXI_MM2S_ADDR_WIDTH = 64 generate
    mm2s_desc_baddress <= mm2s_desc_baddr_msb & mm2s_desc_baddr_lsb;
end generate GEN_NEW_64BIT_BUFADDR;

-- If 32 bit addressing then simply pass lsb out
GEN_NEW_32BIT_BUFADDR : if C_M_AXI_MM2S_ADDR_WIDTH = 32 generate
    mm2s_desc_baddress <= mm2s_desc_baddr_lsb;
end generate GEN_NEW_32BIT_BUFADDR;

-------------------------------------------------------------------------------
-- NEW CURRENT DESCRIPTOR
-------------------------------------------------------------------------------
-- If 64 bit addressing then concatinate msb to lsb
GEN_NEW_64BIT_CURDESC : if C_M_AXI_SG_ADDR_WIDTH = 64 generate
    mm2s_new_curdesc <= mm2s_desc_curdesc_msb & mm2s_desc_curdesc_lsb;
end generate GEN_NEW_64BIT_CURDESC;

-- If 32 bit addressing then simply pass lsb out
GEN_NEW_32BIT_CURDESC : if C_M_AXI_SG_ADDR_WIDTH = 32 generate
    mm2s_new_curdesc <= mm2s_desc_curdesc_lsb;
end generate GEN_NEW_32BIT_CURDESC;

-- Write new current descriptor out on last
--REG_CURDESC_WREN : process(m_axi_sg_aclk)
--    begin
--        if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
         --   if(m_axi_sg_aresetn = '0')then
         --       mm2s_new_curdesc_wren_i <= '0';
         --   -- Write new curdesc on fetch done
         --   elsif(desc_fetch_done_i = '1')then
         --       mm2s_new_curdesc_wren_i <= '1';
         --   else
         --       mm2s_new_curdesc_wren_i <= '0';
         --   end if;

--            if(m_axi_sg_aresetn = '0')then
--                mm2s_new_curdesc_wren_i <= '0';
--            -- Write new curdesc on fetch done
--            else
                mm2s_new_curdesc_wren_i <= desc_fetch_done_i;
--            end if;

--        end if;
--    end process REG_CURDESC_WREN;

--***************************************************************************--
--**                       Descriptor Update Logic                         **--
--***************************************************************************--

--*****************************************************************************
--** Pointer Update Logic
--*****************************************************************************

    -----------------------------------------------------------------------
    -- Capture LSB cur descriptor on write for use on descriptor update.
    -- This will be the address the descriptor is updated to
    -----------------------------------------------------------------------
    UPDT_DESC_WRD0: process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0')then
                    updt_desc_reg0 <= (others => '0');
                elsif(mm2s_new_curdesc_wren_i = '1')then
                    updt_desc_reg0 <= DESC_NOT_LAST
                                      & mm2s_desc_curdesc_lsb;


                -- Shift data out on shift enable
                elsif(updt_shftenbl = '1')then
                    updt_desc_reg0 <= updt_desc_reg1;

                end if;
            end if;
        end process UPDT_DESC_WRD0;

    -----------------------------------------------------------------------
    -- Capture MSB cur descriptor on write for use on descriptor update.
    -- This will be the address the descriptor is updated to
    -----------------------------------------------------------------------
    UPDT_DESC_WRD1: process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0')then
                    updt_desc_reg1 <= (others => '0');
                elsif(mm2s_new_curdesc_wren_i = '1')then
                    updt_desc_reg1 <= DESC_LAST
                                      & mm2s_desc_curdesc_msb;

                -- Shift data out on shift enable
                elsif(updt_shftenbl = '1')then
                    updt_desc_reg1 <= (others => '0');

                end if;
            end if;
        end process UPDT_DESC_WRD1;


    -- Shift in data from SG engine if tvalid, tready, and not on last word
    updt_shftenbl <=  updt_data and updtptr_tvalid and s_axis_mm2s_updtptr_tready;


    -- Update data done when updating data and tlast received and target
    -- (i.e. SG Engine) is ready
    updt_data_clr <= '1' when updtptr_tvalid = '1' and updtptr_tlast = '1'
                          and s_axis_mm2s_updtptr_tready = '1'
                else '0';


    -- When desc data ready for update set and hold flag until
    -- data can be updated to queue.  Note it may
    -- be held off due to update of status
    UPDT_DATA_PROCESS : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0' or updt_data_clr = '1')then
                    updt_data   <= '0';
                -- clear flag when data update complete
 --               elsif(updt_data_clr = '1')then
 --                   updt_data <= '0';
 --               -- set flag when desc fetched as indicated
 --               -- by curdesc wren
                elsif(mm2s_new_curdesc_wren_i = '1')then
                    updt_data <= '1';
                end if;
            end if;
        end process UPDT_DATA_PROCESS;

    updtptr_tvalid  <= updt_data;
    updtptr_tlast   <= updt_desc_reg0(C_S_AXIS_UPDPTR_TDATA_WIDTH);
    updtptr_tdata   <= updt_desc_reg0(C_S_AXIS_UPDPTR_TDATA_WIDTH-1 downto 0);


--*****************************************************************************
--** Status Update Logic
--*****************************************************************************

    mm2s_complete <= '1'; -- Fixed at '1'

    ---------------------------------------------------------------------------
    -- Descriptor queuing turned on in sg engine therefore need to instantiate
    -- fifo to hold fetch buffer lengths.  Also need to throttle fetches
    -- if pointer has not been updated yet or length fifo is full
    ---------------------------------------------------------------------------
    GEN_UPDT_FOR_QUEUE : if C_SG_INCLUDE_DESC_QUEUE = 1 generate
    signal xb_fifo_reset   : std_logic; -- xfer'ed bytes fifo reset
    signal xb_fifo_full    : std_logic; -- xfer'ed bytes fifo full
    begin
        -----------------------------------------------------------------------
        -- Need to flag a pending pointer update to prevent subsequent fetch of
        -- descriptor from stepping on the stored pointer, and buffer length
        -----------------------------------------------------------------------
        REG_PENDING_UPDT : process(m_axi_sg_aclk)
            begin
                if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                    if(m_axi_sg_aresetn = '0' or updt_data_clr = '1')then
                        mm2s_pending_ptr_updt <= '0';
                    elsif (desc_fetch_done_i = '1') then --(mm2s_new_curdesc_wren_i = '1')then
                        mm2s_pending_ptr_updt <= '1';
                    end if;
                end if;
            end process REG_PENDING_UPDT;

        -- Pointer pending update or xferred bytes fifo full
        mm2s_pending_update <= mm2s_pending_ptr_updt or xb_fifo_full;
        updt_pending <= mm2s_pending_update;
        -----------------------------------------------------------------------
        -- On MM2S transferred bytes equals buffer length.  Capture length
        -- on curdesc write.
        -----------------------------------------------------------------------
        XFERRED_BYTE_FIFO : entity proc_common_v3_00_a.srl_fifo_f
          generic map(
            C_DWIDTH        => BUFFER_LENGTH_WIDTH          ,
            C_DEPTH         => 16                           ,
            C_FAMILY        => C_FAMILY
            )
          port map(
            Clk             => m_axi_sg_aclk              ,
            Reset           => xb_fifo_reset                ,
            FIFO_Write      => desc_fetch_done_i, --mm2s_new_curdesc_wren_i      ,
            Data_In         => mm2s_desc_blength_i          ,
            FIFO_Read       => sts_received_re              ,
            Data_Out        => mm2s_xferd_bytes             ,
            FIFO_Empty      => open                         ,
            FIFO_Full       => xb_fifo_full                 ,
            Addr            => open
            );

        xb_fifo_reset      <= not m_axi_sg_aresetn;

        -- clear status received flag in cmdsts_if to
        -- allow more status to be received from datamover
        mm2s_sts_received_clr <= updt_sts_clr;

        -- Generate a rising edge off status received in order to
        -- flag status update
        REG_STATUS : process(m_axi_sg_aclk)
            begin
                if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                    if(m_axi_sg_aresetn = '0')then
                        sts_received_d1 <= '0';
                    else
                        sts_received_d1 <= mm2s_sts_received;
                    end if;
                end if;
            end process REG_STATUS;

        -- CR566306 - status invalid during halt
        --sts_received_re <= mm2s_sts_received and not sts_received_d1;
        sts_received_re <= mm2s_sts_received and not sts_received_d1 and not mm2s_halt_d2;

    end generate GEN_UPDT_FOR_QUEUE;

    ---------------------------------------------------------------------------
    -- If no queue in sg engine then do not need to instantiate a
    -- fifo to hold buffer lengths.   Also do not need to hold off
    -- fetch based on if status has been updated or not because
    -- descriptors are only processed one at a time
    ---------------------------------------------------------------------------
    GEN_UPDT_FOR_NO_QUEUE : if C_SG_INCLUDE_DESC_QUEUE = 0 generate
    begin

        mm2s_sts_received_clr   <= '1'; -- Not needed for the No Queue configuration

        mm2s_pending_update     <= '0'; -- Not needed for the No Queue configuration

        -----------------------------------------------------------------------
        -- On MM2S transferred bytes equals buffer length.  Capture length
        -- on curdesc write.
        -----------------------------------------------------------------------
        REG_XFERRED_BYTES : process(m_axi_sg_aclk)
            begin
                if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                    if(m_axi_sg_aresetn = '0')then
                        mm2s_xferd_bytes <= (others => '0');
                    elsif(mm2s_new_curdesc_wren_i = '1')then
                        mm2s_xferd_bytes <= mm2s_desc_blength_i;
                    end if;
                end if;
            end process REG_XFERRED_BYTES;

        -- Status received based on a DONE or an ERROR from DataMover
        sts_received <= mm2s_done or mm2s_interr or mm2s_decerr or mm2s_slverr;

        -- Generate a rising edge off status received in order to
        -- flag status update
        REG_STATUS : process(m_axi_sg_aclk)
            begin
                if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                    if(m_axi_sg_aresetn = '0')then
                        sts_received_d1 <= '0';
                    else
                        sts_received_d1 <= sts_received;
                    end if;
                end if;
            end process REG_STATUS;

        -- CR566306 - status invalid during halt
        --sts_received_re <= mm2s_sts_received and not sts_received_d1;
        sts_received_re <= sts_received and not sts_received_d1 and not mm2s_halt_d2;

    end generate GEN_UPDT_FOR_NO_QUEUE;



    -----------------------------------------------------------------------
    -- Receive Status SG Update Logic
    -----------------------------------------------------------------------
    -- clear flag when updating status and see a tlast and target
    -- (i.e. sg engine) is ready
    updt_sts_clr <= '1' when updt_sts = '1'
                         and updtsts_tlast = '1'
                         and updtsts_tvalid = '1'
                         and s_axis_mm2s_updtsts_tready = '1'
                else '0';

    -- When status received set and hold flag until
    -- status can be updated to queue.  Note it may
    -- be held off due to update of data
    UPDT_STS_PROCESS : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0' or updt_sts_clr = '1')then
                    updt_sts                <= '0';
                -- clear flag when status update done
                -- or datamover halted
   --             elsif(updt_sts_clr = '1')then
   --                 updt_sts                <= '0';
   --             -- set flag when status received
                elsif(sts_received_re = '1')then
                    updt_sts                <= '1';
                end if;
            end if;
        end process UPDT_STS_PROCESS;

    -----------------------------------------------------------------------
    -- Catpure Status.  Status is built from status word from DataMover
    -- and from transferred bytes value.
    -----------------------------------------------------------------------
    UPDT_DESC_WRD2 : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
                if(m_axi_sg_aresetn = '0')then
                    updt_desc_reg2  <= (others => '0');

                elsif(sts_received_re = '1')then
                    updt_desc_reg2  <= DESC_LAST
                                     & mm2s_tag(DATAMOVER_STS_TAGLSB_BIT)  -- Desc_IOC
                                     & mm2s_complete
                                     & mm2s_decerr
                                     & mm2s_slverr
                                     & mm2s_interr
                                     & RESERVED_STS
                                     & mm2s_xferd_bytes;
                end if;
            end if;
        end process UPDT_DESC_WRD2;


    updtsts_tdata  <= updt_desc_reg2(C_S_AXIS_UPDSTS_TDATA_WIDTH-1 downto 0);
    -- MSB asserts last on last word of update stream
    updtsts_tlast  <= updt_desc_reg2(C_S_AXIS_UPDSTS_TDATA_WIDTH);
    -- Drive tvalid
    updtsts_tvalid <= updt_sts;


    -- Drive update done to mm2s sm for the no queue case to indicate
    -- readyd to fetch next descriptor
    UPDT_DONE_PROCESS : process(m_axi_sg_aclk)
        begin
            if(m_axi_sg_aclk'EVENT and m_axi_sg_aclk = '1')then
       --         if(m_axi_sg_aresetn = '0')then
       --             desc_update_done <= '0';
       --         elsif(updt_sts_clr = '1')then
       --             desc_update_done <= '1';
       --         else
       --            desc_update_done <= '0';
       --        end if;

                if(m_axi_sg_aresetn = '0')then
                    desc_update_done <= '0';
                else
                    desc_update_done <= updt_sts_clr;
                end if;
            end if;
       end process UPDT_DONE_PROCESS;


    -- Update Pointer Stream
    s_axis_mm2s_updtptr_tvalid <= updtptr_tvalid;
    s_axis_mm2s_updtptr_tlast  <= updtptr_tlast and updtptr_tvalid;
    s_axis_mm2s_updtptr_tdata  <= updtptr_tdata ;

    -- Update Status Stream
    s_axis_mm2s_updtsts_tvalid <= updtsts_tvalid;
    s_axis_mm2s_updtsts_tlast  <= updtsts_tlast and updtsts_tvalid;
    s_axis_mm2s_updtsts_tdata  <= updtsts_tdata ;

    -----------------------------------------------------------------------


end implementation;
