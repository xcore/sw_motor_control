/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    mac_custom_filter.h
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
#ifndef _mac_cusom_filter_h_
#define _mac_cusom_filter_h_

#define MAC_FILTER_ARPIP 0x1

inline int mac_custom_filter(unsigned int buf[])
{
  int result = 0;
  unsigned short etype = (unsigned short) buf[3];
  int qhdr = (etype == 0x0081);
 
  if (qhdr) {
    // has a 802.1q tag - read etype from next word
    etype = (unsigned short) buf[4];
  }

  switch (etype) {
    case 0x0608:
    case 0x0008:
      result = MAC_FILTER_ARPIP;
      break;
    default:
      break;
  }

  return result;
}

#endif
