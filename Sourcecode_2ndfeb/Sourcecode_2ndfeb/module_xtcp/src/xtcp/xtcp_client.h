/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    xtcp_client.h
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
#ifndef   _xtcp_client_h_
#define   _xtcp_client_h_
#include <xccompat.h>
#ifdef __XC__
#define NULLABLE ?
#else
#define NULLABLE
#endif

#include "xtcp_client_conf.h"

typedef unsigned int xtcp_appstate_t;

/** XTCP IP address.
 *
 *  This data type represents a single ipv4 address in the XTCP
 *  stack.
 */
typedef unsigned char xtcp_ipaddr_t[4];

/** IP configuration information structure.
 * 
 *  This structure describes IP configuration for an ip node.
 *  
 **/
typedef struct xtcp_ipconfig_t {
  xtcp_ipaddr_t ipaddr;    /**< The IP Address of the node */
  xtcp_ipaddr_t netmask;   /**< The netmask of the node. The mask used 
                                to determine which address are routed locally.*/
  xtcp_ipaddr_t gateway;   /**< The gateway of the node */
} xtcp_ipconfig_t;

/** XTCP protocol type.
 *  
 * This determines what type a connection is: either UDP or TCP.
 *
 **/
typedef enum xtcp_protocol_t {
  XTCP_PROTOCOL_TCP, /**< Transmission Control Protocol */
  XTCP_PROTOCOL_UDP  /**< User Datagram Protocol */
} xtcp_protocol_t;


/** XTCP event type.
 *
 *  The event type represents what event is occuring on a particualr connection.
 *  It is instantiated when an event is received by the client using the 
 *  xtcp_event() function.
 *
 **/
typedef enum xtcp_event_type_t {
  XTCP_NEW_CONNECTION,  /**<  This event represents a new connection has been 
                              made. In the case of a TCP server connections it
                              occurs when a remote host firsts makes contact
                              with the local host. For TCP client connections  
                              it occurs when a stream is setup with the remote
                              host.
                              For UDP connections it occurs as soon as the 
                              connection is created.        **/ 

  XTCP_RECV_DATA,       /**<  This event occurs when the connection has received
                              some data. The client *must* follow receipt of 
                              this event with a call to xtcp_recv() before
                              any other interaction with the server. **/

  XTCP_REQUEST_DATA,    /**<  This event occurs when the server is ready to send
                              data and is requesting that the client send data.
                              This event happens after a call to 
                              xtcp_init_send() from the client.
                              The client *must* follow receipt of this event 
                              with a call to xtcp_send() before any other
                              interaction with the server. */
                                                    
  XTCP_SENT_DATA,       /**<  This event occurs when the server has successfully
                              sent the previous piece of data that was given
                              to it via a call to xtcp_send(). The server
                              is now requesting more data so the client 
                              *must* follow receipt of this event 
                              with a call to xtcp_send() before any other
                              interaction with the server. */

  XTCP_RESEND_DATA,    /**<  This event occurs when the server has failed to
                              send the previous piece of data that was given
                              to it via a call to xtcp_send(). The server
                              is now requesting for the same data to be sent
                              again. The client 
                              *must* follow receipt of this event 
                              with a call to xtcp_send() before any other
                              interaction with the server. */

  XTCP_TIMED_OUT,      /**<   This event occurs when the connection has 
                              timed out with the remote host (TCP only). 
                              This event represents the closing of a connection
                              and is the last event that will occur on
                              an active connection. */

  XTCP_ABORTED,        /**<   This event occurs when the connection has 
                              been aborted by the local or remote host
                              (TCP only). 
                              This event represents the closing of a connection
                              and is the last event that will occur on
                              an active connection. */

  XTCP_CLOSED,         /**<   This event occurs when the connection has
                              been closed by the local or remote host.
                              This event represents the closing of a connection
                              and is the last event that will occur on
                              an active connection. */

  XTCP_POLL,           /**<   This event occurs at regular intervals per
                              connection. Polling can be initiated and 
                              the interval can be set with 
                              xtcp_set_poll_interval() */

  XTCP_IFUP,           /**<   This event occurs when the link goes up (with
                              valid new ip address). This event has no 
                              associated connection. */
                              
  XTCP_IFDOWN,         /**<   This event occurs when the link goes down. 
                              This event has no associated connection. */

  XTCP_ALREADY_HANDLED /**<   This event type does not get set by the server 
                              but can be set by the client to show an event
                              has been handled */
} xtcp_event_type_t;

/** Type representing a connection type.
 *
 */
typedef enum xtcp_connection_type_t {
  XTCP_CLIENT_CONNECTION,  /**< A client connection */
  XTCP_SERVER_CONNECTION   /**< A server connection */
} xtcp_connection_type_t;


/** This type represents a TCP or UDP connection.
 *
 *  This is the main type containing connection information for the client 
 *  to handle. Elements of this type are instantiated by the xtcp_event() 
 *  function which informs the client about an event and the connection
 *  the event is on.
 *
 **/
typedef struct xtcp_connection_t {
  int id;  /**< A unique identifier for the connection */
  xtcp_protocol_t protocol; /**< The protocol of the connection (TCP/UDP) */
  xtcp_connection_type_t connection_type; /**< The type of connection (client/sever) */
  xtcp_event_type_t event; /**< The last reported event on this connection. */
  xtcp_appstate_t appstate; /**< The application state associated with the
                                 connection.  This is set using the 
                                 xtcp_set_connection_appstate() function. */
  xtcp_ipaddr_t remote_addr; /**< The remote ip address of the connection. */
  unsigned int remote_port;  /**< The remote port of the connection. */
  unsigned int local_port;  /**< The local port of the connection. */
  unsigned int mss;  /**< The maximum size in bytes that can be send using
                        xtcp_send() after a send event */
} xtcp_connection_t;


#define XTCP_IPADDR_CPY(dest, src) do { dest[0] = src[0]; \
                                        dest[1] = src[1]; \
                                        dest[2] = src[2]; \
                                        dest[3] = src[3]; \
                                      } while (0)


#define XTCP_IPADDR_CMP(a, b) (a[0] == b[0] && \
                               a[1] == b[1] && \
                               a[2] == b[2] && \
                               a[3] == b[3])

#include "xtcp_blocking_client.h"

/** Convert a unsigned integer representation of an ip address into
 *  the xtcp_ipaddr_t type.
 * 
 * \param ipaddr The result ipaddr
 * \param i      An 32-bit integer containing the ip address (network order)
 */
void xtcp_uint_to_ipaddr(xtcp_ipaddr_t ipaddr, unsigned int i);

/** Listen to a particular incoming port. After this call,
 *  when a connection is established a XTCP_NEW_CONNECTION event is
 *  signalled.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param port_number the local port number to listen to
 * \param proto       the protocol to listen to (TCP or UDP)
 */
void xtcp_listen(chanend c_xtcp, int port_number, xtcp_protocol_t proto);

/** Stop listening to a particular incoming port. Applies to TCP
 *  connections only.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param port_number local port number to stop listening on
 */
void xtcp_unlisten(chanend c_xtcp, int port_number);

/** Try to connect to a remote port.
 * 
 * \param c_xtcp      chanend connected to the xtcp server
 * \param port_number the remote port to try to connect to
 * \param ipaddr      the ip addr of the remote host
 * \param proto       the protocol to connect with (TCP or UDP)
 */
void xtcp_connect(chanend c_xtcp, 
                  int port_number, 
                  xtcp_ipaddr_t ipaddr,
                  xtcp_protocol_t proto);


/** Bind the local end of a connection to a particular port (UDP).
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 * \param port_number the local port to set the connection to
 */
void xtcp_bind_local(chanend c_xtcp, 
                     REFERENCE_PARAM(xtcp_connection_t,  conn),
                     int port_number);

/** Bind the remote end of a connection to a particular port and
 *  ip address. 
 *
 * This is only valid for XTCP_PROTOCOL_UDP connections.
 * After this call, packets sent to this connection will go to 
 * the specified address and port
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 * \param addr        the intended remote address of the connection 
 * \param port_number the intended remote port of the connection
 */
void xtcp_bind_remote(chanend c_xtcp, 
                      REFERENCE_PARAM(xtcp_connection_t, conn), 
                      xtcp_ipaddr_t addr, int port_number);


/** Receive the next connect event. This can be used in a select statement.
 *
 *  Upon receiving the event, the xtcp_connection_t structure conn
 * is instatiated with information of the event and the connection
 * it is on.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection relating to the current event
 */
#ifdef __XC__
transaction xtcp_event(chanend c_xtcp, xtcp_connection_t &conn);
#else
void do_xtcp_event(chanend c_xtcp,  xtcp_connection_t *conn);
#define xtcp_event(x,y) do_xtcp_event(x,y)
#endif


/**  Initiate sending data on a connection. 
 *
 *  After making this call, the
 *  server will respond with a XTCP_REQUEST_DATA event when it is
 *  ready to accept data.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 */
void xtcp_init_send(chanend c_xtcp, 
                    REFERENCE_PARAM(xtcp_connection_t, conn));




/** Set the connections application state data item. After this call, 
 * subsequent events on this connection will have the appstate field
 * of the connection set
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 * \param appstate    An unsigned integer representing the state. In C
 *                    this is usually a pointer to some connection dependent
 *                    information.
 */
void xtcp_set_connection_appstate(chanend c_xtcp, 
                                  REFERENCE_PARAM(xtcp_connection_t, conn), 
                                  xtcp_appstate_t appstate);

/** Close a connection. 
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 */
void xtcp_close(chanend c_xtcp,
                REFERENCE_PARAM(xtcp_connection_t,conn));

/** Abort a connection.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 */
void xtcp_abort(chanend c_xtcp,
                REFERENCE_PARAM(xtcp_connection_t,conn));


/**  Receive data from the server. This should be called after a 
 *  XTCP_RECV_DATA event.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param data        A array to place the received data into
 * \returns           The length of the received data in bytes
 */
int xtcp_recv(chanend c_xtcp, char data[]);

/** Receive data from the server. This should be called after a 
 *  XTCP_RECV_DATA event.
 *  The data is put into the array data starting at index i i.e.
 *  the first byte of data is written to data[i].
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param data        A array to place the received data into
 * \param i           The index where to start filling the data array
 * \returns           The length of the received data in bytes
 */
int xtcp_recvi(chanend c_xtcp, char data[], int i);

/** Set a connection into ack-receive mode.
 *
 *  In ack-receive mode after a receive event the tcp window will be set to
 *  zero for the connection (i.e. no more data will be received from the other end).
 *  This will continue until the client calls the xtcp_ack_recv functions.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 */
void xtcp_ack_recv_mode(chanend c_xtcp,
                        REFERENCE_PARAM(xtcp_connection_t,conn)) ;


/** Ack a receive event
 *  
 * In ack-receive mode this command will acknowledge the last receive and 
 * therefore
 * open the receive window again so new receive events can occur.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param conn        the connection
 **/
void xtcp_ack_recv(chanend c_xtcp,
                   REFERENCE_PARAM(xtcp_connection_t,conn));


/** Send data to the server. This should be called after a 
 *  XTCP_REQUEST_DATA, XTCP_SENT_DATA or XTCP_RESEND_DATA event 
 *  (alternatively xtcp_write_buf can be called). 
 *  To finish sending this must be called with a length  of zero or
 *  call the xtcp_complete_send() function.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param data        An array of data to send
 * \param len         The length of data to send. If this is 0, no data will
 *                    be sent and a XTCP_SENT_DATA event will not occur.
 */
void xtcp_send(chanend c_xtcp,
               char NULLABLE data[],
               int len);

/** Complete a send transaction with the server.
 *
 *  This function can be called after a
 *  XTCP_REQUEST_DATA, XTCP_SENT_DATA or XTCP_RESEND_DATA event 
 *  to finish any sending on the connection that the event
 *  related to.
 *  
 *  \param c_xtcp   chanend connected to the tcp server
 */
inline void xtcp_complete_send(chanend c_xtcp) {
#ifdef __XC__
  xtcp_send(c_xtcp, null, 0);
#else
  xtcp_send(c_xtcp, (void *) 0, 0);
#endif
}

/** Send data to the server. This should be called after a 
 *  XTCP_REQUEST_DATA, XTCP_SENT_DATA or XTCP_RESEND_DATA event 
 *  (alternatively xtcp_write_buf can be called). 
 *  The data is sent starting from index i i.e. data[i] is the first
 *  byte to be sent.
 *  To finish sending this must be called with a length  of zero.
 *
 * \param c_xtcp      chanend connected to the xtcp serve
 * \param data        An array of data to send
 * \param i           The index at which to start reading from the data array
 * \param len         The length of data to send. If this is 0, no data will
 *                    be sent and a XTCP_SENT_DATA event will not occur.
 */
void xtcp_sendi(chanend c_xtcp,
                char NULLABLE data[],
                int i,
                int len);


/** Set the poll interval for a udp connection in seconds. If this is called
 *  then the udp connection will cause a poll event every poll_interval
 *  milliseconds.
 *
 * \param c_xtcp         chanend connected to the xtcp server
 * \param conn           the connection
 * \param poll_interval  the required poll interval in milliseconds
 */
void xtcp_set_poll_interval(chanend c_xtcp,
                            REFERENCE_PARAM(xtcp_connection_t, conn),
                            int poll_interval);

/** Subscribe to a particular ip multicast group address
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param addr        The address of the multicast group to join. It is
 *                    assumed that this is a multicast IP address.
 */
void xtcp_join_multicast_group(chanend c_xtcp,
                               xtcp_ipaddr_t addr);

/** Unsubscribe to a particular ip multicast group address
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param addr        The address of the multicast group to leave. It is
 *                    assumed that this is a multicast IP address which
 *                    has previously been joined.
 */
void xtcp_leave_multicast_group(chanend c_xtcp,
                               xtcp_ipaddr_t addr);

/** Get the current host MAC address of the server.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param mac_addr    the array to be filled with the mac address
 **/
void xtcp_get_mac_address(chanend c_xtcp, unsigned char mac_addr[]);

/** Get the current host IP configuration of the server.
 *
 * \param c_xtcp      chanend connected to the xtcp server
 * \param ipconfig    the structure to be filled with the IP configuration
 *                    information
 **/
void xtcp_get_ipconfig(chanend c_xtcp, 
                       REFERENCE_PARAM(xtcp_ipconfig_t, ipconfig));

#endif // _xtcp_client_h_

