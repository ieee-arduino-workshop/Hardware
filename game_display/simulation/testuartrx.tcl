  #input        clk50,
  #input        rst_n,
  #input  [3:0] uart_baud,
  #input        rx_in,
  #output [7:0] rx_data,
  #output       rx_empty,
  #input  [7:0] tx_data,
  #output reg   tx_out,  
  #output [7:0] test


proc runSim {} {
	

	#clear the waveform editor
	restart -force -nowave 
	#add all the waveforms to the waveform window
	add wave *

	#generate a clock waveform with 50ps high time and repeat every 100ps
	force -deposit clk50 1 0, 0 {10ns} -repeat 20ns
	force -freeze rst_n 0
	force -freeze rx_in 1
	run 200
	force -freeze rst_n 1
	run 5000

	force -freeze rx_in 0
	run 1000
	force -freeze rx_in 1
	run 2000
	#start bit
	force -freeze rx_in 0
	run 2000
	#bits 1 and 2
	force -freeze rx_in 1 
	run 4000
	#bit 3
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#bit 5
	force -freeze rx_in 1
	run 2000
	#bit 6
	force -freeze rx_in 1
	run 2000
	#bit 7
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#stop bit 1
	force -freeze rx_in 1
	run 2000
	#stop bit 2
	force -freeze rx_in 1
	run 2000
	run 4000


		#start bit
	force -freeze rx_in 0
	run 2000
	#bits 1 and 2
	force -freeze rx_in 1 
	run 4000
	#bit 3
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#bit 5
	force -freeze rx_in 1
	run 2000
	#bit 6
	force -freeze rx_in 0
	run 2000
	#bit 7
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 0
	run 2000
	#stop bit 1
	force -freeze rx_in 1
	run 2000
	#stop bit 2
	force -freeze rx_in 1
	run 2000
	run 4000


		#start bit
	force -freeze rx_in 0
	run 2000
	#bits 1 and 2
	force -freeze rx_in 1 
	run 4000
	#bit 3
	force -freeze rx_in 1
	run 2000
	#bit 4
	force -freeze rx_in 0
	run 2000
	#bit 5
	force -freeze rx_in 1
	run 2000
	#bit 6
	force -freeze rx_in 0
	run 2000
	#bit 7
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#stop bit 1
	force -freeze rx_in 1
	run 2000
	#stop bit 2
	force -freeze rx_in 1
	run 2000
	run 4000


			#start bit
	force -freeze rx_in 0
	run 2000
	#bits 1 and 2
	force -freeze rx_in 1 
	run 4000
	#bit 3
	force -freeze rx_in 1
	run 2000
	#bit 4
	force -freeze rx_in 0
	run 2000
	#bit 5
	force -freeze rx_in 1
	run 2000
	#bit 6
	force -freeze rx_in 1
	run 2000
	#bit 7
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#stop bit 1
	force -freeze rx_in 1
	run 2000
	#stop bit 2
	force -freeze rx_in 1
	run 2000
	run 4000


			#start bit
	force -freeze rx_in 0
	run 2000
	#bits 1 and 2
	force -freeze rx_in 0
	run 4000
	#bit 3
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#bit 5
	force -freeze rx_in 1
	run 2000
	#bit 6
	force -freeze rx_in 0
	run 2000
	#bit 7
	force -freeze rx_in 0
	run 2000
	#bit 4
	force -freeze rx_in 1
	run 2000
	#stop bit 1
	force -freeze rx_in 1
	run 2000
	#stop bit 2
	force -freeze rx_in 1
	run 2000
	run 8000


}