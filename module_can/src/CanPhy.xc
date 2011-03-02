/**
 * Module:  module_can
 * Version: 0v1alpha0
 * Build:   f3df1fffb2ce4e2d971ab9860f95a89cc6f5136b
 * File:    CanPhy.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
/*
 * CanPhy.xc
 *
 * Summary:
 *   Implements a CAN RX/TX in one 100 MIPS thread.
 *
 * I/Os:
 *   Packets are received from the bus on the canRx port - a 1-bit buffered port.
 *   Packets are sent on the canTx port - a 1-bit unbuffered port.
 *
 * Data interfaces:
 *   Packets correctly received are sent to the next layer over rxChan. Packets to
 *   be sent are received over txChan. It requires the packet send/receiving not to
 *   pause.
 *
 * Error handling:
 *   Bit errors, stuffing errors, form errors and CRC errors are detected. All invalid
 *   packets are simply discarded for when receiving. Errors on trasmission cause it
 *   to retry.
 *
 * Notes:
 *   Does not check that the DLC <= 8 on transmit. Assumes that this is correct.
 *
 * To do:
 *   Support various bitrates - only 1Mb tested so far
 *   Test error cases
 *
 */
#include <string.h>
#include <xs1.h>
#include <xclib.h>

#include "CanIncludes.h"
#include "CanFunctions.h"
#include "CanCFunctions.h"

#ifdef DEBUG
#include <print.h>
#endif

int alignTable[34];

/*
 * Local functions - not designed to be used outside of this file
 */
inline void rxStateMachine(struct CanPhyState &phyState, struct CanPacket &rxPacket,
		chanend rxChan, buffered in port:32 canRx, port canTx,
		int &counter, unsigned int &allBits, unsigned int &dataBits, unsigned int &time);
inline void txStateMachine(struct CanPhyState &phyState, struct CanPacket &rxPacket, struct CanPacket &txPacket,
		buffered in port:32 canRx, port canTx,
		int &counter, unsigned int &allBits, unsigned int &dataBits, unsigned int &time);
void handleError(struct CanPhyState &phyState, struct CanPacket &rxPacket, struct CanPacket &txPacket,
		buffered in port:32 canRx, port canTx, unsigned int &time);
inline void signalError(struct CanPhyState &phyState, port canTx, ERROR error, int &done);
void setupPorts(clock clk, buffered in port:32 canRx, port canTx);
void waitForBusIdle(struct CanPhyState &phyState, buffered in port:32 canRx, port canTx);
void manageBusOff(struct CanPhyState &phyState, buffered in port:32 canRx, port canTx);
int crc15(int nxtBit, unsigned int crc_rg);
int crc15with0(unsigned int crc_rg);

/*
 * The top-level
 */
#pragma unsafe arrays
void canPhyRxTx(chanend rxChan, chanend txChan, clock clk, buffered in port:32 canRx, port canTx) {

	struct CanPhyState phyState;
	struct CanPacket rxPacket;
	struct CanPacket txPacket;

	int          counter = 0;
	unsigned int allBits = 0;
	unsigned int dataBits = 0;
	unsigned int time = 0;

	initPacket(txPacket);
	setupPorts(clk, canRx, canTx);

	phyState.state = STATE_BUS_IDLE;
	phyState.error = ERROR_NONE;
	phyState.txComplete = 1;
	phyState.activeError = 1;
	phyState.rxErrorCount = 0;
	phyState.txErrorCount = 0;

#ifdef DEBUG
	printstrln("CanPhy starting");
#endif

	// Ensure the state machines don't start mid-packet
	waitForBusIdle(phyState, canRx, canTx);

	while(1) {
		#pragma xta label "phyLoop"
		allBits = 1;
		phyState.packetCrc = 0;
		phyState.state = STATE_SOF;
		phyState.txActive = 0;
		rxPacket.IEB = 0;

		if (phyState.txComplete) {
			unsigned int txPacketNum;

			// Uses inline assembler to ensure that the RX port is monitoring
			// for the line to go low at all times, even when receiving a packet
			// to transmit.
			asm("setd res[%0], %1" :: "r"(canRx), "r"(0));
			asm("setc res[%0], %1" :: "r"(canRx), "r"(XS1_SETC_COND_EQ));

			select {
				#pragma xta endpoint "txPacketRxStart"
				case inuint_byref(txChan, txPacketNum):
					receivePacket(txChan, txPacket);
					phyState.txComplete = 0;
					break;

				case rxReady(canRx, time):
					asm("getts %0, res[%1]" : "=r"(time) : "r"(canRx));
					break;
			}
		}

		if (!phyState.txComplete) {
			int x;
			int doSend = 1;

			// Take SOF bit into account
			allBits = allBits << 1;

			// Need to test again whether the RX has started while the packet
			// to send was being received
			select {
				case rxReady(canRx, time):
					asm("getts %0, res[%1]" : "=r"(time) : "r"(canRx));
					doSend = 0;

					// Move to end of the SOF bit
					time += QUANTA_TOTAL;
					break;
				default:
					break;
			}

			if (doSend) {
				#pragma xta endpoint "txPacketRxEnd"
				canTx <: 0 @ time;
				phyState.txActive = 1;

				txStateMachine(phyState, rxPacket, txPacket, canRx, canTx,
						counter, allBits, dataBits, time);

			} else {
				// Move state machine past SOF bit
				rxPacket.SOF = 0;
				counter = 11;
				dataBits = 0;
				phyState.state = STATE_ID;
			}

			if (!phyState.txComplete && (phyState.error == ERROR_NONE)) {
				// TX not complete - continue receiving the packet
				phyState.txActive = 0;
				rxStateMachine(phyState, rxPacket, rxChan, canRx, canTx,
						counter, allBits, dataBits, time);
			}

		} else {
			rxStateMachine(phyState, rxPacket, rxChan, canRx, canTx,
					counter, allBits, dataBits, time);
		}

		if (phyState.error) {
			handleError(phyState, rxPacket, txPacket, canRx, canTx, time);
		}
	}
}

#pragma unsafe arrays
inline void rxStateMachine(struct CanPhyState &phyState, struct CanPacket &rxPacket,
		chanend rxChan, buffered in port:32 canRx, port canTx,
		int &counter, unsigned int &allBits, unsigned int &dataBits, unsigned int &time) {

	int done = 0;
	int bitStuffingActive = 1;

	// Set up to align clock to sample between PHASE1 & PHASE2
	unsigned int zeros = 33;

	while (!done) {
		#pragma xta label "rxLoop"
		unsigned int bit;
		unsigned int rxWord;

		// Move time on to the end of the next bit. This table defines the
		// next bit time in order to handle syncrhonization with falling edges.
		time += alignTable[zeros];

		// Read the port at the end of a bit time. There are 25 samples per bit,
		// so the 32-bit buffered port gives enough history to read the bit and
		// manage synchronization.
		#pragma xta endpoint "startRx"
		canRx @ time :> rxWord;

		// The data bit is extracted from the sample between PHASE1 and PHASE2
		bit = rxWord >> 31;
		allBits = (allBits << 1) | bit;

		// The leading zeros count allows synchronization to falling edges
		zeros = clz(rxWord);

		// Manage bit stuffing. If 5 consecutive bits have been received, then
		// expect the inverse stuffing bit. Stuffing bits are ignored for CRC
		// and the state machine. They are also only active from SOF till the
		// end of the CRC.
		#pragma xta label "excludeRx"
		if (bitStuffingActive && (((sext(allBits >> 1, 5) + 1) >> 1) == 0)) {
			// If there have been six in a row it is an error
			if (((sext(allBits, 6) + 1) >> 1) == 0) {
				signalError(phyState, canTx, ERROR_STUFF_ERROR, done);
			} else {
				// Discard stuffing bit
			}

		} else {
			switch (phyState.state) {
			case STATE_SOF:
				rxPacket.SOF = bit;
				counter = 11;
				dataBits = 0;
				phyState.state = STATE_ID;
				// No need to do CRC as it has no affect (bit is 0)
				break;

			case STATE_ID:
				counter--;
				dataBits = (dataBits << 1) | bit;
				if (counter == 0) {
					rxPacket.ID = dataBits;
					phyState.state = STATE_SRR;
				}
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_SRR:
				rxPacket.SRR = bit;
				phyState.state = STATE_IEB;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_IEB:
				rxPacket.IEB = bit;
				if (rxPacket.IEB == 1) {
					counter = 18;
					dataBits = 0;
					phyState.state = STATE_EID;
				} else {
					rxPacket.RTR = rxPacket.SRR;
					rxPacket.RB1 = rxPacket.IEB;
					phyState.state = STATE_RB0;
				}
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_EID:
				counter--;
				dataBits = (dataBits << 1) | bit;
				if (counter == 0) {
					rxPacket.EID = dataBits;
					phyState.state = STATE_RTR;
				}
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_RTR:
				rxPacket.RTR = bit;
				phyState.state = STATE_RB1;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_RB1:
				rxPacket.RB1 = bit;
				phyState.state = STATE_RB0;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_RB0:
				rxPacket.RB0 = bit;
				counter = 4;
				dataBits = 0;
				phyState.state = STATE_DLC;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_DLC:
				counter--;
				dataBits = (dataBits << 1) | bit;
				if (counter == 0) {
					int dlc = dataBits;
					rxPacket.DLC = dlc;

					dataBits = 0;
					if (dlc == 0) {
						counter = 15;
						phyState.state = STATE_CRC;
					} else if (dlc > 8) {
						signalError(phyState, canTx, ERROR_FORM_ERROR, done);
					} else {
						phyState.state = STATE_DATA_BIT7;
					}
				}
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_DATA_BIT7:
				dataBits = bit;
				phyState.state = STATE_DATA_BIT6;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT6:
				dataBits = (dataBits << 1) | bit;
				phyState.state = STATE_DATA_BIT5;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT5:
				dataBits = (dataBits << 1) | bit;
				phyState.state = STATE_DATA_BIT4;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT4:
				dataBits = (dataBits << 1) | bit;
				phyState.state = STATE_DATA_BIT3;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT3:
				dataBits = (dataBits << 1) | bit;
				phyState.state = STATE_DATA_BIT2;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT2:
				dataBits = (dataBits << 1) | bit;
				phyState.state = STATE_DATA_BIT1;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT1:
				dataBits = (dataBits << 1) | bit;
				phyState.state = STATE_DATA_BIT0;
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;
			case STATE_DATA_BIT0:
				rxPacket.DATA[counter] = (dataBits << 1) | bit;
				counter++;
				if (counter == rxPacket.DLC) {
					dataBits = 0;
					counter = 15;
					phyState.state = STATE_CRC;
				} else {
					phyState.state = STATE_DATA_BIT7;
				}
				phyState.packetCrc = crc15(bit, phyState.packetCrc);
				break;

			case STATE_CRC:
				counter--;
				dataBits |= bit << counter;
				if (counter == 0) {
					rxPacket.CRC = dataBits;

					if (rxPacket.CRC != (phyState.packetCrc & 0x7FFF)) {
						signalError(phyState, canTx, ERROR_CRC_ERROR, done);
					} else {
						phyState.state = STATE_CRC_DEL;
					}
				}
				break;

			case STATE_CRC_DEL:
				bitStuffingActive = 0;
				rxPacket.CRC_DEL = bit;
				if (rxPacket.CRC_DEL == 0) {
					signalError(phyState, canTx, ERROR_BIT_ERROR, done);
				} else {
					canTx <: 0; // Drive the ACK for next bit time
					phyState.state = STATE_ACK;
				}
				break;

			case STATE_ACK:
				// Stop driving the ACK bit
				canTx :> void;
				phyState.state = STATE_ACK_DEL;
				break;

			case STATE_ACK_DEL:
				rxPacket.ACK_DEL = bit;
				if (rxPacket.CRC_DEL == 0) {
					signalError(phyState, canTx, ERROR_BIT_ERROR, done);
				} else {
					phyState.state = STATE_EOF;
				}
				break;

			case STATE_EOF: {
				#pragma xta endpoint "excludeRxEof"
				// Send the packet to the higher level while monitoring for the bus
				// to go low. If the bus goes low then there is an error.
				asm("setd res[%0], %1" :: "r"(canRx), "r"(0));
				asm("setc res[%0], %1" :: "r"(canRx), "r"(XS1_SETC_COND_EQ));

				outuint(rxChan, 0);
				sendPacket(rxChan, rxPacket);

				// Manage the RX error count on successful receipt of a packet
				if (phyState.rxErrorCount > 127) {
					phyState.rxErrorCount = 127;
				} else if (phyState.rxErrorCount > 0) {
					phyState.rxErrorCount -= 1;
				}

				select {
	 				case rxReady(canRx, time):
						asm("getts %0, res[%1]" : "=r"(time) : "r"(canRx));
						signalError(phyState, canTx, ERROR_BIT_ERROR, done);
						break;
					case canTx @ (time + QUANTA_TOTAL * 6) :> void:
						asm("setc res[%0], %1" :: "r"(canRx), "r"(XS1_SETC_COND_NONE));
						counter = 0;
						phyState.state = STATE_INTERMISSION;
						time += QUANTA_TOTAL * 6;
						break;
				}
				break;
			}

			case STATE_INTERMISSION:
				counter++;
				if (bit == 0) {
					counter = 0;
					phyState.state = STATE_OVERLOAD;
				} else if (counter == 3) {
					phyState.state = STATE_BUS_IDLE;
					done = 1;
				}
				break;

			case STATE_OVERLOAD:
				counter++;
				if (bit == 1) {
					counter = 0;
					phyState.state = STATE_OVERLOAD_DEL;
				}
				break;

			case STATE_OVERLOAD_DEL:
				counter++;
				if (counter == 8) {
					phyState.state = STATE_BUS_IDLE;
					done = 1;
				}
				break;
			}
		}
	}
}

/*
 * The TX state machine is constructed in the same way as the RX state machine.
 * This makes it possible to go from sending a packet to receiving if arbitration
 * is lost. Hence there is some state kept up to date at the start of the state
 * machine which will only be used if arbitration is lost.
 *
 * The state machine only gets updated when a bit has been successfully sent so
 * that there is no need to back track when arbitration is lost. The CRC and bit
 * to send are kept ahead of the state machine.
 */
#pragma unsafe arrays
inline void txStateMachine(struct CanPhyState &phyState, struct CanPacket &rxPacket, struct CanPacket &txPacket,
		buffered in port:32 canRx, port canTx,
		int &counter, unsigned int &allBits, unsigned int &dataBits, unsigned int &time) {

	#pragma xta label "excludeTx"
	int done = 0;

	int crcActive = 1;
	unsigned int currentCrc = 0;
	unsigned int nextBit = txPacket.ID >> 10;
	unsigned int nextCrc = crc15(nextBit, 0);

	int bitStuffingActive = 1;

	while (!done) {
		#pragma xta label "txLoop"
		unsigned int rxBit = 0;
		unsigned int txBit = nextBit;
		unsigned int expectBit = allBits & 1;

		// Move time on to the end of the next bit
		time += QUANTA_TOTAL;

		// Sample the bus at the defined sample point between PHASE1 & PHASE2.
		// If the bit has been sucessfully transmitted continue, else arbitration
		// has been lost or an error has occurred.
		#pragma xta endpoint "txCheckBit"
		canRx @ (time - QUANTA_PHASE2 - 1) :> rxBit;
		rxBit = rxBit >> 31;

		if (rxBit == expectBit) {
			// Last bit was trasmitted ok, update statemachine and select
			// next bit to transmit. The next bit to transmit is ahead of the
			// state machine by 2 steps. This is because the bit ahead by 1 step
			// is currently sitting in the port ready to be written on the next
			// bit time, so the bit after that is needed.
			int sendStuffBit = 0;

			// Manage bit stuffing. If 5 consecutive bits have been sent, then
			// send the inverse bit. Stuffing bits are ignored for CRC and only
			// active from SOF till the end of the CRC.
			if (bitStuffingActive && (((sext(allBits, 5) + 1) >> 1) == 0)) {
				sendStuffBit = 1;
				txBit = expectBit ^ 1;
			}

			// Set up bit to send in the next bit time.
			#pragma xta endpoint "sendBit"
			canTx @ time <: txBit;

			allBits = (allBits << 1) | txBit;

			if (!sendStuffBit) {
				phyState.packetCrc = currentCrc;
				currentCrc = nextCrc;

				switch (phyState.state) {
				case STATE_SOF:
					counter = 11;
					dataBits = 0;
					phyState.state = STATE_ID;
					nextBit = txPacket.ID >> 9;
					break;

				case STATE_ID: {
					int txIeb = txPacket.IEB;
					counter--;
					dataBits = (dataBits << 1) | rxBit;
					if (counter == 0) {
						rxPacket.ID = dataBits;
						if (txIeb) {
							nextBit = txIeb;
							phyState.state = STATE_SRR;
						} else {
							nextBit = txPacket.RB1;
							phyState.state = STATE_RTR;
						}
					} else if (counter == 1) {
						if (txIeb) {
							nextBit = txPacket.SRR;
						} else {
							nextBit = txPacket.RTR;
						}
					} else {
						nextBit = txPacket.ID >> (counter - 2);
					}
					break;
				}

				case STATE_SRR:
					rxPacket.SRR = rxBit;
					nextBit = txPacket.EID >> 17;
					phyState.state = STATE_IEB;
					break;

				case STATE_IEB:
					rxPacket.IEB = rxBit;
					counter = 18;
					dataBits = 0;
					nextBit = txPacket.EID >> 16;
					phyState.state = STATE_EID;
					break;

				case STATE_EID:
					counter--;
					dataBits = (dataBits << 1) | rxBit;
					if (counter == 0) {
						rxPacket.EID = dataBits;
						nextBit = txPacket.RB1;
						phyState.state = STATE_RTR;
					} else if (counter == 1) {
						nextBit = txPacket.RTR;
					} else {
						nextBit = txPacket.EID >> (counter - 2);
					}
					break;

				case STATE_RTR:
					nextBit = txPacket.RB0;
					phyState.state = STATE_RB1;
					break;

				case STATE_RB1:
					nextBit = txPacket.DLC >> 3;
					phyState.state = STATE_RB0;
					break;

				case STATE_RB0:
					counter = 4;
					nextBit = txPacket.DLC >> 2;
					phyState.state = STATE_DLC;
					break;

				case STATE_DLC: {
					int dlc = txPacket.DLC;
					counter--;
					if (counter == 0) {
						if (dlc == 0) {
							counter = 15;
							nextBit = nextCrc >> 13;
							phyState.state = STATE_CRC;
						} else {
							nextBit = txPacket.DATA[0] >> 6;
							phyState.state = STATE_DATA_BIT7;
						}
					} else if (counter == 1) {
						if (dlc == 0) {
							crcActive = 0;
							nextBit = nextCrc >> 14;
						} else {
							nextBit = txPacket.DATA[0] >> 7;
						}
					} else {
						nextBit = dlc >> (counter - 2);
					}
					break;
				}

				case STATE_DATA_BIT7:
					nextBit = txPacket.DATA[counter] >> 5;
					phyState.state = STATE_DATA_BIT6;
					break;
				case STATE_DATA_BIT6:
					nextBit = txPacket.DATA[counter] >> 4;
					phyState.state = STATE_DATA_BIT5;
					break;
				case STATE_DATA_BIT5:
					nextBit = txPacket.DATA[counter] >> 3;
					phyState.state = STATE_DATA_BIT4;
					break;
				case STATE_DATA_BIT4:
					nextBit = txPacket.DATA[counter] >> 2;
					phyState.state = STATE_DATA_BIT3;
					break;
				case STATE_DATA_BIT3:
					nextBit = txPacket.DATA[counter] >> 1;
					phyState.state = STATE_DATA_BIT2;
					break;
				case STATE_DATA_BIT2:
					nextBit = txPacket.DATA[counter];
					phyState.state = STATE_DATA_BIT1;
					break;
				case STATE_DATA_BIT1:
					if ((counter + 1) == txPacket.DLC) {
						crcActive = 0;
						nextBit = nextCrc >> 14;
					} else {
						nextBit = txPacket.DATA[counter + 1] >> 7;
					}
					phyState.state = STATE_DATA_BIT0;
					break;
				case STATE_DATA_BIT0:
					counter++;
					if (counter == txPacket.DLC) {
						counter = 15;
						nextBit = nextCrc >> 13;
						phyState.state = STATE_CRC;
					} else {
						nextBit = txPacket.DATA[counter] >> 6;
						phyState.state = STATE_DATA_BIT7;
					}
					break;

				case STATE_CRC:
					counter--;
					if (counter == 0) {
						txPacket.CRC = phyState.packetCrc;
						nextBit = 1;
						phyState.state = STATE_CRC_DEL;
						bitStuffingActive = 0;
					} else if (counter == 1) {
						nextBit = 1;
					} else {
						nextBit = nextCrc >> (counter - 2);
					}
					break;

				case STATE_CRC_DEL:
					nextBit = 1;
					// Change the expected bit
					allBits = allBits & ~1;
					phyState.state = STATE_ACK;
					break;

				case STATE_ACK:
					nextBit = 1;
					phyState.state = STATE_ACK_DEL;
					break;

				case STATE_ACK_DEL:
					counter = 7;
					nextBit = 1;
					phyState.state = STATE_EOF;
					break;

				case STATE_EOF:
					counter--;
					nextBit = 1;
					if (counter == 0) {
						int txErrorCount = phyState.txErrorCount;
						phyState.state = STATE_INTERMISSION;
						phyState.txComplete = 1;

						// Manage the RX error count on successful transmission of a packet
						if (txErrorCount > 0) {
							phyState.txErrorCount = txErrorCount - 1;
						}
					}
					break;

				case STATE_INTERMISSION:
					counter++;
					nextBit = 1;
					if (counter == 3) {
						phyState.state = STATE_BUS_IDLE;
						done = 1;
					}
					break;
				}
			}
			nextBit = nextBit & 0x1;
			if (crcActive) {
				nextCrc = crc15(nextBit, currentCrc);
			}

		} else {
			// When the bit driven is not the bit received there is either
			// an error or arbitration has been lost.
			done = 1;

			switch (phyState.state) {
			case STATE_SOF:
				// Keep this case to prevent compiler having to do a sub
				signalError(phyState, canTx, ERROR_BIT_ERROR, done);
				break;

			case STATE_ID:
				counter--;
				if (counter == 0) {
					rxPacket.ID = dataBits;
					phyState.state = STATE_SRR;
				}
				phyState.packetCrc = crc15with0(phyState.packetCrc);
				break;

			case STATE_SRR:
				rxPacket.SRR = 0;
				phyState.state = STATE_IEB;
				phyState.packetCrc = crc15with0(phyState.packetCrc);
				break;

			case STATE_IEB:
				rxPacket.IEB = 0;
				rxPacket.RTR = rxPacket.SRR;
				rxPacket.RB1 = 0;
				phyState.state = STATE_RB0;
				phyState.packetCrc = crc15with0(phyState.packetCrc);
				break;

			case STATE_EID:
				counter--;
				if (counter == 0) {
					rxPacket.EID = dataBits;
					phyState.state = STATE_RTR;
				}
				phyState.packetCrc = crc15with0(phyState.packetCrc);
				break;

			case STATE_RTR:
				rxPacket.RTR = 0;
				phyState.state = STATE_RB1;
				phyState.packetCrc = crc15with0(phyState.packetCrc);
				break;

			case STATE_ACK:
				signalError(phyState, canTx, ERROR_NO_ACK, done);
				break;

			default:
				signalError(phyState, canTx, ERROR_BIT_ERROR, done);
				break;

			}

			// Correct the last bit sent to match one seen for stuffing
			allBits = allBits & ~1;
		}
	}

	// Stop driving - not strictly necessary if continuing to drive 1. However
	// it makes it easier to debug if the direction of the port changes.
	canTx :> void;
}

#pragma unsafe arrays
inline void handleError(struct CanPhyState &phyState, struct CanPacket &rxPacket, struct CanPacket &txPacket,
		buffered in port:32 canRx, port canTx, unsigned int &time) {

	#pragma xta label "excludeHandleError"
	int lastBit = 0;
	int rxWord = 0;
	int countError = 1;

	if (phyState.error == ERROR_CRC_ERROR) {
		// Signal error after ACK_DEL - other errors have already been signaled
		// by signalError function
		time += QUANTA_TOTAL;
		canTx @ time <: ~phyState.activeError;
	}

	if (!phyState.txActive) {
		// Align the output time to clock edge
		time += QUANTA_PHASE2;
	}

	if (phyState.activeError) {
		// Hold bit for error flag time
		time += QUANTA_TOTAL * 6;

		// Send error delimiter
		canTx @ time <: 1;

		canRx @ time :> rxWord;
		time += QUANTA_TOTAL;

		lastBit = (rxWord << QUANTA_PHASE2) >> 31;
		if (!phyState.txActive && (lastBit == 0)) {
			phyState.rxErrorCount += 8;
		}

		for (int i = 0; lastBit == 0 && i < 6; i++) {
			canRx @ time :> rxWord;
			time += QUANTA_TOTAL;
			lastBit = (rxWord << QUANTA_PHASE2) >> 31;
		}

		// Send remaining recessive bits
		for (int i = 0; i < 7; i++) {
			canTx @ time <: 1;
			time += QUANTA_TOTAL;
		}
	} else {
		// Hold rest of passive error flag
		time += QUANTA_TOTAL * 6;

		// Sample last bit to see whether anyone else has signaled an error
		canRx @ time :> rxWord;
		lastBit = (rxWord << QUANTA_PHASE2) >> 31;

		if (lastBit == 1 && phyState.txActive) {
			// Prevent error count going to bus idle when there are no
			// other devices on bus to ACK the packets
			countError = 0;
		}
	}

	if (phyState.txActive && countError) {
		phyState.txErrorCount += 8;
	} else {
		phyState.rxErrorCount += 1;
	}
	phyState.activeError = (phyState.txErrorCount < 128) && (phyState.rxErrorCount < 128);

#ifdef DEBUG
	printstr("Error ");
	printint(phyState.error);
	printstr(" in state ");
	printint(phyState.state);
	printstr(" phyState.CRC ");
	printhexln(phyState.packetCrc & 0x7FFF);
	printPacket(rxPacket);
	//while(1);
#endif

	if (phyState.txErrorCount >= 256) {
		manageBusOff(phyState, canRx, canTx);
	}

	phyState.state = STATE_BUS_IDLE;
}

/*
 * Errors need to be flagged as soon as possible - next bit in most cases
 */
inline void signalError(struct CanPhyState &phyState, port canTx, ERROR error, int &done) {
	if (phyState.error == ERROR_CRC_ERROR) {
		// Do nothing now - error signalled after ACK_DEL
	} else {
		// Send first error bit instantly
		#pragma xta endpoint "sendError"
		canTx <: ~phyState.activeError;
	}
	#pragma xta label "excludeSignalError"
	phyState.error = error;
	done = 1;
}


/*
 * Ensure that the bus is in the BUS_IDLE state before starting the state machines
 */
void waitForBusIdle(struct CanPhyState &phyState, buffered in port:32 canRx, port canTx) {
	unsigned time;
	int done = 0;

	while (!done) {
		// Wait for bus to be high
		canRx when pinseq(1) :> void @ time;

		select {
		case canRx when pinseq(0) :> void:
			// Bus not high for long enough
			break;
		case canTx @ (time + (QUANTA_TOTAL * 7)) :> void:
			done = 1;
			break;
		}
	}
}

/*
 * When the device goes into "bus off" it needs to wait for 128 consecutive
 * sequences of 11 recessive bits before it can come out of "bus off"
 */
void manageBusOff(struct CanPhyState &phyState, buffered in port:32 canRx, port canTx) {
	unsigned time;
	int done = 0;

	while (!done) {
		// Wait for bus to be high
		canRx when pinseq(1) :> void @ time;

		select {
		case canRx when pinseq(0) :> void:
			// Bus not high for long enough
			break;
		case canTx @ (time + (QUANTA_TOTAL * 128 * 11)) :> void:
			done = 1;
			break;
		}
	}
	// Reset the error counters
	phyState.activeError = 1;
	phyState.rxErrorCount = 0;
	phyState.txErrorCount = 0;
}

/*
 * Configure the ports to be clocked of the provided clock block.
 * The clock block is divided down to ensure there are 25 (QUANTA_TOTAL)
 * samples per bit time.
 */
void setupPorts(clock clk, buffered in port:32 canRx, port canTx) {
	initAlignTable();

	configure_clock_ref(clk, CLOCK_DIV);
	configure_in_port_no_ready(canRx, clk);
	set_port_clock(canTx, clk);

	// Only required for simulation as there is no external pull up
	#ifdef SIM_TESTING
		set_port_pull_up(canTx);
		set_port_pull_up(canRx);
	#endif

	start_clock(clk);
}

/*
 * Implement the CRC function defined by the CAN specification.
 *
 * Note: does not mask off the result to the 15 bits in order to
 *       save this computation on every path. Masking done when
 *       comparing the CRC with packet CRC.
 */
int crc15(int nxtBit, unsigned int crc_rg) {
	#pragma xta label "excludeCrc"
	int crc_nxt = (nxtBit ^ (crc_rg >> 14)) & 0x1;
	crc_rg = crc_rg << 1;
	if (crc_nxt) {
		crc_rg = crc_rg ^ 0x4599;
	}
	return crc_rg;
}

/*
 * Special case when the data is known to be 0
 */
int crc15with0(unsigned int crc_rg) {
	#pragma xta label "excludeCrc"
	int crc_nxt = (crc_rg >> 14) & 0x1;
	crc_rg = crc_rg << 1;
	if (crc_nxt) {
		crc_rg = crc_rg ^ 0x4599;
	}
	return crc_rg;
}
