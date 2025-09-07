# DNS Zone File Templates

This file provides example DNS zone file templates for various configurations.

## Forward Zone File Template

```
$TTL    86400
@       IN      SOA     ns1.example.com. admin.example.com. (
                     2023010101     ; Serial
                         86400     ; Refresh
                          7200     ; Retry
                        604800     ; Expire
                         86400 )   ; Negative Cache TTL
;
; Name servers
@       IN      NS      ns1.example.com.
@       IN      NS      ns2.example.com.

; A records for name servers
ns1     IN      A       192.168.1.10
ns2     IN      A       192.168.1.11

; Domain records
@       IN      A       192.168.1.10
www     IN      A       192.168.1.10

; Mail records
@       IN      MX      10 mail.example.com.
mail    IN      A       192.168.1.10

; SPF record for email validation
@       IN      TXT     "v=spf1 mx a -all"

; DKIM record for email validation
mail._domainkey IN      TXT     "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."

; DMARC record for email policy
_dmarc  IN      TXT     "v=DMARC1; p=none; sp=none; rua=mailto:admin@example.com"

; SRV records for services
_ldap._tcp      IN      SRV     0 0 389 ldap.example.com.
_xmpp._tcp      IN      SRV     0 0 5222 xmpp.example.com.

; CNAME records
ftp     IN      CNAME   www.example.com.
webmail IN      CNAME   mail.example.com.
```

## Reverse Zone File Template

```
$TTL    86400
@       IN      SOA     ns1.example.com. admin.example.com. (
                     2023010101     ; Serial
                         86400     ; Refresh
                          7200     ; Retry
                        604800     ; Expire
                         86400 )   ; Negative Cache TTL
;
; Name servers
@       IN      NS      ns1.example.com.
@       IN      NS      ns2.example.com.

; PTR Records
10      IN      PTR     example.com.
10      IN      PTR     www.example.com.
10      IN      PTR     mail.example.com.
```

## BIND Configuration Templates

### named.conf.options

```
options {
    directory "/var/cache/bind";
    
    // Listen on specific addresses
    listen-on {
        127.0.0.1;
        192.168.1.10;
    };
    listen-on-v6 { ::1; };
    
    // Configure forwarders
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    
    // Enable DNSSEC validation
    dnssec-validation auto;
    
    // Allow recursive queries from trusted networks only
    allow-recursion {
        localhost;
        192.168.1.0/24;
    };
    
    // Only allow zone transfers to specific servers
    allow-transfer {
        localhost;
        192.168.1.11; // Secondary DNS
    };
    
    // Prevent cache poisoning
    additional-from-auth no;
    additional-from-cache no;
    
    // Hide version
    version "DNS Server";
};
```

### named.conf.local

```
// Forward zone
zone "example.com" {
    type master;
    file "/etc/bind/zones/db.example.com";
    allow-update { none; };
};

// Reverse zone
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.1";
    allow-update { none; };
};
```
