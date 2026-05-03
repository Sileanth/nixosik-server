#!/bin/bash

DOMAIN="sileanth.pl"
# IPs from hosts.nix
NS0="84.235.172.161"   # main
NS1="134.98.151.178"  # kotek
NS2="134.98.136.184"  # piesek

echo "--- Testing DNS Setup for $DOMAIN ---"

check_ns() {
    local name=$1
    local ip=$2
    echo -e "\n[Testing $name @ $ip]"
    
    # Check A record
    echo -n "  A record for $DOMAIN: "
    result=$(dig +short @$ip $DOMAIN)
    if [ -z "$result" ]; then echo "FAILED"; else echo "$result"; fi
    
    # Check NS records
    echo -n "  NS records: "
    ns_results=$(dig +short @$ip $DOMAIN NS | tr '\n' ' ')
    if [ -z "$ns_results" ]; then echo "FAILED"; else echo "$ns_results"; fi
    
    # Check wildcard
    echo -n "  Wildcard test (test.$DOMAIN): "
    wildcard=$(dig +short @$ip test.$DOMAIN)
    if [ -z "$wildcard" ]; then echo "FAILED"; else echo "$wildcard"; fi
}

check_ns "ns0 (main)"   $NS0
check_ns "ns1 (kotek)"  $NS1
check_ns "ns2 (piesek)" $NS2

echo -e "\n--- Summary ---"
echo "If any say 'FAILED', ensure BIND is running and port 53 is open on that host."
