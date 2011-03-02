/**
 * Module:  module_dsc_sdram
 * Version: 1v0alpha0
 * Build:   80df1998143a2e168c213da76618b92b21a94693
 * File:    sdram_test.xc
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
/* TODO get rid of write() - pass data directly from generating loops */

#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include <syscall.h>
#include "dsc_sdram.h"

#define N SDRAM_PACKET_NWORDS

#define assert_ecall(e) asm("ecallf %0" :: "r"(e))

void _DoXlinkSyscall(int oscall, int ret);

void die(int ret)
{
#ifdef CHIPLVL
  /* avoid channel declaration check */
  asm("mov r1, %0" :: "r"(ret));
  asm("ldc r0, 0");
  asm("bl _DoXlinkSyscall");
#else
  /* do not use exit() to allow exiting from inside a transaction */
  _exit(ret);
#endif
}

static void uswait(int us)
{
  timer T;
  int t;
  T :> t;
  for (int i = 0; i < us; i++) {
    t += 100;
    T when timerafter(t) :> void;
  }
}

static void write(chanend c, int address, const int data[N])
{
  c <: 1;
  master {
    c <: address;
    for (int i = 0; i < N; i++) {
      c <: data[i];
    }
  }
}

void init_only(chanend c)
{
  uswait(300);
  die(0);
}

void single_write(chanend c)
{
  int data[N];

  for (int i = 0; i < 4 * N; i++) {
    (data, char[])[i] = i + 1;
  }
  write(c, 0x12 | (0x345 << 9) | (2 << 22), data);

  uswait(100);
  die(0);
}

void two_writes(chanend c)
{
  int data[N];

  /* write a packet */
  for (int i = 0; i < 4 * N; i++) {
    (data, char[])[i] = i + 1;
  }
  write(c, 0, data);

  /* write a packet */
  for (int i = 0; i < 4 * N; i++) {
    (data, char[])[i] = (i + 1) << 1;
  }
  write(c, N * 4, data);

  uswait(100);
  die(0);
}

void read_little(chanend c)
{
  /* read a packet */
  c <: 2;
  slave {
    for (int i = 0; i < 32; i++) {
      c :> int;
    }
    die(0);
  }
}

void write_and_read(chanend c)
{
  int data[N], returned[32];

  /* write a packet */
  for (int i = 0; i < 4 * N; i++) {
    (data, char[])[i] = i;
  }
  write(c, 0, data);

  /* read a packet and check */
  c <: 2;
  slave {
    for (int i = 0; i < 32; i++) {
      c :> returned[i];
    }
    for (int i = 0; i < 4 * N; i++) {
      assert_ecall((returned, char[])[i] == (i & 0xFF));
    }
    die(0);
  }
}

void multiple_read(chanend c)
{
  int k;
  int data[N], returned[128];

  /* write 4 consecutive packets */
  k = 1;
  for (int j = 0; j < 4; j++) {
    for (int i = 0; i < 4 * N; i++) {
      (data, char[])[i] = k;
      k++;
    }
    write(c, N * 2 * j, data);
  }

  /* read 4 packets back and check */
  c <: 2;
  slave {
    for (int i = 0; i < 128; i++) {
      c :> returned[i];
    }
    k = 1;
    for (int j = 0; j < 4; j++) {
      for (int i = 0; i < 4 * N; i++) {
        assert_ecall((returned, char[])[(4 * N) * j + i] == (k & 0xFF));
        k++;
      }
    }
    die(0);
  }
}

void self_refresh(chanend c)
{
  int data[N], returned[32];

  /* write a packet */
  for (int i = 0; i < 4 * N; i++) {
    (data, char[])[i] = i + 1;
  }
  write(c, 0, data);

  /* wait 2 minutes */
  printf("moment...\n");
  for (int i = 0; i < 120; i++) {
    uswait(1000000);
  }

  /* read a packet and check */
  c <: 2;
  slave {
    for (int i = 0; i < 32; i++) {
      c :> returned[i];
    }
    for (int i = 0; i < 4 * N; i++) {
      assert_ecall((returned, char[])[i] == ((i + 1) & 0xFF));
    }
    die(0);
  }
}

void full_range(chanend c)
{
  int k;
  int data[N], returned[N];

  /* fill the SDRAM */
  k = 1;
  for (int j = 0; j < SDRAM_NWORDS / N; j++) {
    for (int i = 0; i < 4 * N; i++) {
      (data, char[])[i] = k;
      k++;
    }
    write(c, N * 2 * j, data);
  }

  /* read and check all */
  c <: 2;
  slave {
    k = 1;
    for (int j = 0; j < SDRAM_NWORDS / N; j++) {
      for (int i = 0; i < N; i++) {
        c :> returned[i];
      }
      for (int i = 0; i < 4 * N; i++) {
        assert_ecall((returned, char[])[i] == (k & 0xFF));
        k++;
      }
    }
  }

  /* fill the SDRAM with different data */
  k = -1;
  for (int j = 0; j < SDRAM_NWORDS / N; j++) {
    for (int i = 0; i < 4 * N; i++) {
      (data, char[])[i] = k;
      k--;
    }
    write(c, N * 2 * j, data);
  }

  /* read and check all */
  c <: 2;
  slave {
    k = -1;
    for (int j = 0; j < SDRAM_NWORDS / N; j++) {
      for (int i = 0; i < N; i++) {
        c :> returned[i];
      }
      for (int i = 0; i < 4 * N; i++) {
        assert_ecall((returned, char[])[i] == (k & 0xFF));
        k--;
      }
    }
  }

  die(0);
}

void stress_test(chanend c)
{
  int k;
  int data[N], returned[N];

  /* fill the SDRAM */
  k = 1;
  for (int j = 0; j < SDRAM_NWORDS / N; j++) {
    for (int i = 0; i < 4 * N; i++) {
      (data, char[])[i] = k;
      k++;
    }
    write(c, N * 2 * j, data);
  }

  /* wait 2 minutes */
  printf("moment...\n");
  for (int i = 0; i < 120; i++) {
    uswait(1000000);
  }

  /* read and check all (with 1ms between packets to encourage refresh issues) */
  printf("moment...\n");
  c <: 2;
  slave {
    k = 1;
    for (int j = 0; j < SDRAM_NWORDS / N; j++) {
      for (int i = 0; i < N; i++) {
        c :> returned[i];
      }
      for (int i = 0; i < 4 * N; i++) {
        assert_ecall((returned, char[])[i] == (k & 0xFF));
        k++;
      }
      uswait(1000);
    }
  }

  die(0);
}

int traffic_f()
{
  return 5;
}

void traffic()
{
  int a[16];
  asm("mov r5, %0" :: "r"(a));
  while (1) {
    asm("bl traffic_f");
    asm("ldw r8, r5[0]");
    asm("ldw r7, r5[1]");
    asm("bl traffic_f");
    asm("stw r6, r5[2]");
  }
}

void test(chanend c)
{
#ifdef CHIPLVL
  //init_only(c);
  //single_write(c);
  //two_writes(c);
  read_little(c);
#else
  //write_and_read(c);
  //multiple_read(c);
  //self_refresh(c);
  //full_range(c);
  stress_test(c);
#endif
}

int main()
{
  chan c;
#ifdef CHIPLVL
  /* avoid multi-core init */
  par {
    sdram(c);
    test(c);
  }
#else
  par {
    on stdcore[0] : par {
      sdram(c);
      traffic();
      traffic();
      traffic();
      traffic();
      traffic();
      traffic();
      traffic();
    }
    on stdcore[1] : test(c);
  }
#endif
  return 0;
}
