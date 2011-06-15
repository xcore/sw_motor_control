SOURCE = mac.xc libotp_l1.a xp-dsc-bldc.xn
FLAGS = -Wall -g -O3 -I. -report

ifeq "$(OS)" "Windows_NT"
DELETE = del
else
DELETE = rm -f
endif

write_mac.xe: ${SOURCE}
	xcc ${FLAGS} ${SOURCE} -o write_otp.xe

clean:
	$(DELETE) *.o *.a *.xi *.s *.xe *.xb
