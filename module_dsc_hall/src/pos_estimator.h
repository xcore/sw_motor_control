/**
 * Module:  module_dsc_hall
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    pos_estimator.h
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
#ifndef _POS_ESTIMATOR_H_
#define _POS_ESTIMATOR_H_

	// initialise the position estimation
	void init_pos_estimation( );

	// do an update on information from hall
	unsigned pos_hall_update(unsigned ticks);

	#ifdef __XC__
		// get theta value
		unsigned get_pos( unsigned inc, int &pos, unsigned &ticks );
	#else
		// get theta value
		unsigned get_pos( unsigned inc, int *pos, unsigned *ticks );
	#endif

#endif /* _POS_ESTIMATOR_H_ */
