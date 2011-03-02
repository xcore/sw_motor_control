/**
 * Module:  module_locks
 * Version: 1v1
 * Build:   d3c5347cdae4e3489ef0484a98cf3e6824343bb6
 * File:    swlock.c
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
#include "hwlock.h"

hwlock_t global_hwlock;

typedef unsigned swlock_t;

static void init_swlocks(void) __attribute__((constructor));

static void init_swlocks(void)
{
  global_hwlock = __hwlock_init();
}

void free_swlocks(void)
{
  __hwlock_close(global_hwlock);
}

/* Locks */

void spin_lock_init(volatile swlock_t *lock)
{
  *lock = 0;
}

void spin_lock_close(volatile swlock_t *lock)
{
  /* Do nothing */
}

void spin_lock_acquire(volatile swlock_t *lock, 
                       hwlock_t hwlock)
{
  int value;
  do {
    asm(".xtaloop 1\n");
    __hwlock_acquire(hwlock);
    value = *lock;
    *lock = 1;
    __hwlock_release(hwlock);
  } while (value);
}

int spin_lock_try_acquire(volatile swlock_t *lock,
                                 hwlock_t hwlock)
{
  int value;
  __hwlock_acquire(hwlock);
  value = *lock;
  *lock = 1;
  __hwlock_release(hwlock);
  return !value;
}

void spin_lock_release(volatile swlock_t *lock,
                                     hwlock_t hwlock)
{
  __hwlock_acquire(hwlock);
  *lock = 0;
  __hwlock_release(hwlock);
}
