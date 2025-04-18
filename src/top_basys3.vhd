library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_clk_2hz : std_logic;
    signal w_clk_1khz : std_logic;
    signal w_floor_0: STD_LOGIC_VECTOR (3 downto 0);
    signal w_floor_2: STD_LOGIC_VECTOR (3 downto 0);
    signal w_data: STD_LOGIC_VECTOR (3 downto 0);
    --signal w_sel: STD_LOGIC_VECTOR (3 downto 0);
    --signal w_seg_n: STD_LOGIC_VECTOR (6 downto 0);
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
    clk_div_2hz: clock_divider
        generic map ( k_DIV => 25000000  ) --2hz clock from 100mhz, 100mhz/50mhz = 2 hz. 25 000 000 (25 million) since the value is doubled
        port map(
            i_clk => clk,
            i_reset => btnL, --or btnU), --might have to make different. Also might have to make k_div the right value for both dividers
            
            o_clk => w_clk_2hz
            --o_clk => led(15)
        );
    
    clk_div_1khz: clock_divider
        generic map ( k_DIV => 50000  )--1khz clock from 100mhz, 100mhz/100 khz = 1 khz. 50 khz (50 000) since the value is doubled
        port map(
            i_clk => clk,
            i_reset => btnL, --or btnU), --might have to make different. Also might have to make k_div the right value for both dividers
            
            o_clk => w_clk_1khz
        );
    
    elevator_fsm_0: elevator_controller_fsm
        port map(
            i_clk => w_clk_2hz,
            i_reset => btnR, --OR btnU
            go_up_down => sw(1),
            is_stopped => sw(0),
            
            o_floor => w_floor_0 --may have to flip the assignment ?
        );
    
    elevator_fsm_2: elevator_controller_fsm
        port map(
            i_clk => w_clk_2hz,
            i_reset => btnR, --OR btnU
            go_up_down => sw(15),
            is_stopped => sw(14),
           
            o_floor => w_floor_2 --may have to flip the assignment ?
        );
     
     TDM: TDM4
        port map(
            i_clk => w_clk_1khz,
            i_reset => btnU,
            i_D0 => w_floor_0,
            i_D1 => "1111",--F
            i_D2 => w_floor_2,
            i_D3 => "1111",--F
            
            o_data => w_data,
            --o_sel => w_sel
            o_sel => an(3 downto 0)
            
        );
        
     sevensegDC: sevenseg_decoder
        port map(
            i_hex => w_data,
            --o_seg_n => w_seg_n
            o_seg_n => seg(6 downto 0)
        ); 
        
        
    
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	led(15) <= w_clk_2hz;
	led (14 downto 0) <= "000000000000000";
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
