# Protocol

All peers send identically formatted datagrams between each other.

## Datagrams

### Message update

+ Datagram structure ID
+ Source address and port
+ Hops (counter, incremented every time a datagram is forwarded)
+ Source nick
+ Timestamp (whole seconds)
+ Message number (counter)
+ Message version (counter)
+ Message text
+ Signature (covers "Source nick", "Timestamp", "Message number",
  "Message version" and "Message text")

Message update datagrams with an invalid signature are discarded.

Message update datagrams arriving too early (by time stamp) are discarded.

Message update datagrams arriving too late (by message version) are discarded.

If a message update datagram with hops=0 is received, then "Source address and
port" are substituted with the observed values (to correct for NAT).


### Disconnect

+ (to be described)


### Who is around?

+ (to be described)


### This is my public key

+ (to be described)

