# fpga-fm
Simple FM SDR implementation on an FPGA, targeting the DE4 devboard

FM is accomplished through DSBSC modulation. A 95MHz carrier is generated in a PLL, but this could be varied to define the approximate band to transmit in.
An NCO generates a 5MHz intermediate frequency which is multiplied with the carrier to produce sidebands at 90MHz and 100MHz.
Since the NCO frequency can be controlled in logic, it can be varied up and down slightly (by about +- 0.05MHz) 
Varying the NCO frequency moves the position of the sidebands on the frequency spectrum.
Doing so quickly results in an FM audio signal that can be received at 90 or 100MHz on a commercial FM radio set

# emissions warning
RF emissions are generally controlled, and the transmitter circuit is deliberately lacking an antenna to minimise the power of radiated signals
To further reduce the output power and unwanted harmonics, the IO standards for the output pins should be set for minimum current drive and slew rate
