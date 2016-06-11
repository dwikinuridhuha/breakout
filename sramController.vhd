library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sramController is
	generic(
		CLK_RATE : positive := 50_000_000 -- Clk rate in hertz
	);
	port(
		clk : in Std_Logic; -- 50 MHz clock
		rst : in Std_Logic; -- Asynchronous reset
		addr : in  Std_Logic_Vector (22 downto 0); -- Memory address
		data_m2s : in Std_Logic_Vector (15 downto 0); -- The data from the memory controller that will be written : into the memory (used for write operations)
		mem : in Std_Logic; -- Control signal to : initiate a memory operation (mem='0' : initiates a memory cycle)
		rw : in Std_Logic; -- Control signal to : indicate whether the memory operation is a read (rw='1') or a write (rw='0')
		data_s2m : out Std_Logic_Vector (15 downto 0); -- The data from the memory to the memory controller (obta: ined from a read operation)
		data_valid : out Std_Logic; -- : indicates that the data on the 'data_s2m' port is valid
		ready : out Std_Logic; -- : indicates whether the memory controller is ready for a memory operation
		MemAdr : out  Std_Logic_Vector (22 downto 0); -- The address p: ins to the memory device
		MemOE : out Std_Logic; -- : output enable pin to memory device
		MemWR : out Std_Logic; -- Write enable pin to memory device
		RamCS : out Std_Logic; -- Memory chip select (CE#)
		RamLB : out Std_Logic; -- Memory 'lower byte' control signal
		RamUB : out Std_Logic; -- Memory 'upper byte' control signal
		RamCLK : out Std_Logic; -- Memory CLK signal
		RamADV : out Std_Logic; -- Memory ADV signal
		RamCRE : out Std_Logic; -- Memory CRE signal
		MemDB : inout Std_Logic_Vector (15 downto 0) -- Data pins to memory
	);
	function log2c (n: integer) return integer is
		variable m, p: integer;
	begin
		m := 0;
		p := 1;
		while p < n loop
			m := m + 1;
			p := p * 2;
		end loop;
		return m;
	end log2c;
end sramController;

architecture Behavioral of sramController is
	-- State machine signals
	type state_type is (power_up, idle, r1, r2, r3, r4);
	signal state_reg, state_next : state_type := power_up;
	-- Data path signals
	signal addr_reg, addr_next : Std_Logic_Vector (22 downto 0) := (others => '0');
	signal m2s_reg, m2s_next : Std_Logic_Vector (15 downto 0) := (others => '0');
	signal s2m_reg, s2m_next : Std_Logic_Vector (15 downto 0) := (others => '0');
	signal oe_reg, oe_next : Std_Logic := '1';
	signal ce : Std_Logic;
	signal data_ready_reg, data_ready_next : Std_Logic := '0';
	-- Clock divider signals
	constant POWER_UP_TIME : positive := 150_000; -- Power up time in nano seconds
	constant POWER_UP_MAX : positive := (POWER_UP_TIME/10000)*(CLK_RATE/100000);
	constant DIVIDER_WIDTH : positive := log2c(POWER_UP_MAX);
	signal clk_divider : Unsigned(DIVIDER_WIDTH downto 0) := (others => '0');
begin
	-- Set the listed signals to low at all times.
	RamCLK <= '0';
	RamADV <= '0';
	RamCRE <= '0';
	RamLB <= '0';
	RamUB <= '0';
	
	-- Registers
	process(clk, rst)
	begin
		if (rst = '1') then
			state_reg <= power_up;
			addr_reg <= (others => '0');
			m2s_reg <= (others => '0');
			s2m_reg <= (others => '0');
         oe_reg <='1';
			data_ready_reg <= '0';
		elsif (clk'event and clk = '1') then
			state_reg <= state_next;
			addr_reg <= addr_next;
			m2s_reg <= m2s_next;
			s2m_reg <= s2m_next;
         oe_reg <= oe_next;
			data_ready_reg <= data_ready_next;
		end if;
	end process;
	
	-- Next-state logic & data path functional units/routing
   process(state_reg, mem, rw, MemDB, addr, m2s_reg, s2m_reg, addr_reg, clk_divider, data_m2s, data_ready_reg)
   begin
		-- Default values
      addr_next <= addr_reg;
      m2s_next <= m2s_reg;
      s2m_next <= s2m_reg;
      ready <= '0';
		ce <= '0';
		data_ready_next <= data_ready_reg;
		
		-- State and data path logic
      case state_reg is
			when power_up =>
				ce <= '1';
				if (clk_divider = POWER_UP_MAX) then
					state_next <= idle;
				else
					state_next <= power_up;
				end if;
         when idle =>
            if (mem='1') then
               state_next <= idle;
            else -- Back to back operation
               addr_next <= addr;
               if rw='1' then --read
						data_ready_next <= '0';
                  state_next <= r1;
               end if;
            end if;
            ready <= '1';
         when r1 =>
            state_next <= r2;
				data_ready_next <= '0';
         when r2 =>
            state_next <= r3;
         when r3 =>
            state_next <= r4;
			when r4 =>
				if (mem='1') then
               state_next <= idle;
            else -- Back to back operation
               addr_next <= addr;
               if rw='1' then -- Read
                  state_next <= r1;
               end if;
            end if;
            s2m_next <= MemDB;
				data_ready_next <= '1';
      end case;
   end process;
   -- look-ahead output logic
   process(state_next)
   begin
      oe_next <= '1';
      case state_next is
			when power_up =>
         when idle =>
         when r1 =>
         when r2 =>
            oe_next <= '0';
         when r3 =>
            oe_next <= '0';
		 when r4 =>
			oe_next <= '0';
      end case;
   end process;
	
	--  Output logic
   MemWR <= '1';
   MemOE <= oe_reg;
   MemAdr <= addr_reg;
	MemDB <= (others => 'Z');
	data_s2m <= s2m_reg;
	RamCS <= ce;
	data_valid <= data_ready_reg;
	
	-- Clk divider
	process(clk)
	begin
		if (clk'event and clk = '1') then
			if (clk_divider = POWER_UP_MAX) then
				clk_divider <= (others => '0');
			else
				clk_divider <= clk_divider + 1;
			end if;
		end if;
	end process;
end Behavioral;

