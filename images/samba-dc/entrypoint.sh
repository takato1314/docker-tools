#!/bin/sh -e

if [ -z "$NETBIOS_NAME" ]; then
  NETBIOS_NAME=$(hostname -s | tr [a-z] [A-Z])
else
  NETBIOS_NAME=$(echo $NETBIOS_NAME | tr [a-z] [A-Z])
fi
NAMESERVER=$(hostname -i | awk '{print $1}')
REALM=$(echo "$REALM" | tr [a-z] [A-Z])
WORKGROUP=$(echo $WORKGROUP | tr [a-z] [A-Z])
HOST_NAME=$(echo $NETBIOS_NAME.$REALM | tr [A-Z] [a-z])

# Configure timezone
if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  echo 'Set timezone to' $TZ
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

# Configure hosts
echo "$NAMESERVER    $HOST_NAME $(echo $NETBIOS_NAME | tr [A-Z] [a-z])" >> /etc/hosts

if [ $DOMAIN_ACTION == provision ]; then
  # Configure DNS Resolver
  > /etc/resolv.conf
  echo "search $REALM" >> /etc/resolv.conf
  echo "nameserver $NAMESERVER" >> /etc/resolv.conf
  # Create Reverse Lookup Zone
  # samba-tool dns zonecreate $NAMESERVER 0.99.10.in-addr.arpa
fi

# Provisioning Samba AD in Non-interactive Mode
if [ ! -f /var/lib/samba/registry.tdb ]; then
  ADMIN_PASSWORD=$(echo $ADMIN_PASSWORD)
  if [ "$BIND_INTERFACES_ONLY" == yes ]; then
    INTERFACE_OPTS="--option=\"bind interfaces only=yes\" \
      --option=\"interfaces=$INTERFACES\""
  fi
  if [ $DOMAIN_ACTION == provision ]; then
    PROVISION_OPTS="--server-role=dc --use-rfc2307 --domain=$WORKGROUP \
    --realm=$REALM --adminpass='$ADMIN_PASSWORD'"
  elif [ $DOMAIN_ACTION == join ]; then
    PROVISION_OPTS="$REALM DC -UAdministrator --password='$ADMIN_PASSWORD'"
  else
    echo 'Only provision and join actions are supported.'
    exit 1
  fi

  rm -f /etc/samba/smb.conf /etc/krb5.conf

  # This step is required for INTERFACE_OPTS to work as expected
  echo "samba-tool domain $DOMAIN_ACTION $PROVISION_OPTS $INTERFACE_OPTS \
     --dns-backend=SAMBA_INTERNAL" | sh

  mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo 'root = administrator' > /etc/samba/smbusers
fi

# Configure Samba AD
mkdir -p -m 700 /etc/samba/conf.d
for file in /etc/samba/smb.conf /etc/samba/conf.d/netlogon.conf \
      /etc/samba/conf.d/sysvol.conf; do
  sed -e "s:{{ ALLOW_DNS_UPDATES }}:$ALLOW_DNS_UPDATES:" \
      -e "s:{{ BIND_INTERFACES_ONLY }}:$BIND_INTERFACES_ONLY:" \
      -e "s:{{ DOMAIN_LOGONS }}:$DOMAIN_LOGONS:" \
      -e "s:{{ DOMAIN_MASTER }}:$DOMAIN_MASTER:" \
      -e "s+{{ INTERFACES }}+$INTERFACES+" \
      -e "s:{{ LOG_LEVEL }}:$LOG_LEVEL:" \
      -e "s:{{ NETBIOS_NAME }}:$NETBIOS_NAME:" \
      -e "s:{{ REALM }}:$(echo $REALM | tr [A-Z] [a-z]):" \
      -e "s:{{ SERVER_STRING }}:$SERVER_STRING:" \
      -e "s:{{ WINBIND_USE_DEFAULT_DOMAIN }}:$WINBIND_USE_DEFAULT_DOMAIN:" \
      -e "s:{{ WORKGROUP }}:$WORKGROUP:" \
      /root/$(basename $file).j2 > $file
done
for file in $(ls -A /etc/samba/conf.d/*.conf); do
  echo "include = $file" >> /etc/samba/smb.conf
done

# Configure Kerberos Client
ln -fns /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Start samba
exec samba --model=$MODEL -i </dev/null
