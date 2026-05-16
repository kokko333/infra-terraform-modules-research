#!/bin/bash

mkdir -p /var/www/html
cat > /var/www/html/index.html <<EOF
<h1>${server_text}</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} -h /var/www/html &
