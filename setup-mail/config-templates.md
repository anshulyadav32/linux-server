# Mail Server Configuration Files

This directory contains configuration templates for various mail services, including multiple options for SMTP, IMAP/POP3, and webmail components.

## Postfix Templates

### main.cf.template
```
# Basic configuration
smtpd_banner = $myhostname ESMTP $mail_name
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level = may
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtp_tls_security_level = may

# Network settings
myhostname = mail.example.com
myorigin = example.com
mydestination = $myhostname, localhost.example.com, localhost, example.com
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

# Virtual domains and users
virtual_mailbox_domains = example.com
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_alias_maps = hash:/etc/postfix/virtual
virtual_minimum_uid = 100
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000

# SMTP restrictions
smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_rbl_client zen.spamhaus.org,
    reject_rhsbl_reverse_client dbl.spamhaus.org,
    reject_rhsbl_helo dbl.spamhaus.org,
    reject_rhsbl_sender dbl.spamhaus.org
```

## IMAP/POP3 Server Templates

### Dovecot Templates

#### dovecot.conf.template
```
# Basic configuration
protocols = imap pop3 lmtp
listen = *, ::
log_path = /var/log/dovecot.log
info_log_path = /var/log/dovecot-info.log
```

### Courier Templates

#### imapd.template
```
# Courier IMAP server configuration
AUTHMODULES="authdaemon"
IMAPDSSLSTART=YES
IMAPDSTARTTLS=YES
IMAP_CAPABILITY="IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE"
MAXDAEMONS=40
MAXPERIP=20
PIDFILE=/var/run/courier/imapd.pid
TCPDOPTS="-nodnslookup -noidentlookup"
```

#### authdaemonrc.template
```
# Courier authentication daemon configuration
authmodulelist="authuserdb authpam"
daemons=5
authdaemonvar=/var/run/courier/authdaemon
DEBUG_LOGIN=0
DEFAULTOPTIONS=""
LOGGEROPTS=""
```

### 10-mail.conf.template
```
mail_location = maildir:/var/mail/vhosts/%d/%n
namespace inbox {
  inbox = yes
}
mail_privileged_group = mail
mail_access_groups = mail
```

### 10-auth.conf.template
```
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext
!include auth-passwdfile.conf.ext
password_format = PLAIN-MD5
```

### auth-passwdfile.conf.ext.template
```
passdb {
  driver = passwd-file
  args = scheme=PLAIN-MD5 username_format=%u /etc/dovecot/users
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
```

## Webmail Templates

### Roundcube Templates

#### config.inc.php.template
```php
<?php
$config = array();
$config['db_dsnw'] = 'sqlite:////var/lib/roundcube/roundcube.db';
$config['default_host'] = 'localhost';
$config['default_port'] = 143;
$config['smtp_server'] = 'localhost';
$config['smtp_port'] = 25;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['support_url'] = '';
$config['product_name'] = 'Webmail';
$config['des_key'] = 'random-generated-key';
$config['plugins'] = array('archive', 'zipdownload');
$config['skin'] = 'elastic';
$config['enable_spellcheck'] = true;
$config['spellcheck_engine'] = 'pspell';
$config['language'] = 'en_US';
```

### SquirrelMail Templates

#### config.php.template
```php
<?php
$domain                 = 'example.com';
$imapServerAddress      = 'localhost';
$imapPort               = 143;
$useSendmail            = false;
$smtpServerAddress      = 'localhost';
$smtpPort               = 25;
$sendmail_path          = '/usr/sbin/sendmail';
$attachment_dir         = '/var/local/squirrelmail/attach/';
$theme_default          = 'default_theme.php';
$default_charset        = 'iso-8859-1';
```

## msmtp Templates

### msmtprc.template
```
# Default settings
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

# Local SMTP server
account        local
host           localhost
port           25
from           user@example.com
auth           off
tls            off

# Default account
account default : local
```

## SpamAssassin Templates

### local.cf.template
```
# SpamAssassin configuration
required_score          3.0
use_bayes               1
bayes_auto_learn        1
report_safe             0
use_razor2              1
use_pyzor               1
allow_user_rules        1

# Tests
score URIBL_BLACK       10.0
score URIBL_SBL         8.0
score RCVD_IN_PBL       8.0
score RCVD_IN_XBL       8.0
score RCVD_IN_SBL       8.0

# Whitelist and blacklist
whitelist_from          *@gmail.com
whitelist_from          *@yahoo.com
whitelist_from          *@hotmail.com
```

## OpenDKIM Templates

### opendkim.conf.template
```
# OpenDKIM configuration
Syslog                  yes
UMask                   022
KeyTable                refile:/etc/opendkim/key.table
SigningTable            refile:/etc/opendkim/signing.table
ExternalIgnoreList      refile:/etc/opendkim/trusted.hosts
InternalHosts           refile:/etc/opendkim/trusted.hosts
Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
Socket                  local:/var/run/opendkim/opendkim.sock
```

## DNS Record Templates

### DNS Records for Mail Server
```
; MX Record
example.com.    IN    MX    10 mail.example.com.

; A Record for mail subdomain
mail.example.com.    IN    A    <YOUR_SERVER_IP>

; SPF Record
example.com.    IN    TXT    "v=spf1 mx a ip4:<YOUR_SERVER_IP> ~all"

; DKIM Record
mail._domainkey.example.com.    IN    TXT    "v=DKIM1; k=rsa; p=<GENERATED_PUBLIC_KEY>"

; DMARC Record
_dmarc.example.com.    IN    TXT    "v=DMARC1; p=none; sp=none; rua=mailto:postmaster@example.com; ruf=mailto:postmaster@example.com; fo=1; adkim=r; aspf=r; pct=100; rf=afrf"
```
