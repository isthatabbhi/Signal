data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  count                  = 2
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name != "" ? var.key_name : null

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd cronie
    systemctl enable --now httpd
    systemctl enable --now crond
    cat > /usr/local/bin/status-page.sh <<'SCRIPT'
    #!/bin/bash
    NAME="${var.project_name}-web-${count.index + 1}"
    NOW=$(TZ=Asia/Kolkata date +"%d-%m-%Y %I:%M %p")
    UP_SECS=$(cut -d. -f1 /proc/uptime)
    UPTIME="$((UP_SECS/86400))d $((UP_SECS%86400/3600))h $((UP_SECS%3600/60))m"
    LOAD=$(cut -d' ' -f1-3 /proc/loadavg)
    MEM=$(free -m | awk '/Mem:/ {printf "%d MB / %d MB (%d%%)", $3, $2, $3/$2*100}')
    DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')
    IP=$(hostname -I | awk '{print $1}')
    cat > /var/www/html/index.html <<HTML
    <!doctype html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="60">
    <title>$NAME status</title>
    <style>
    body{font-family:Arial,Helvetica,sans-serif;background:#0f172a;color:#e2e8f0;margin:0;padding:48px}
    h1{font-size:28px;margin-bottom:6px}
    .sub{color:#94a3b8;margin-bottom:28px}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;max-width:960px}
    .card{background:#1e293b;border:1px solid #334155;border-radius:10px;padding:18px}
    .card .k{font-size:12px;color:#94a3b8;text-transform:uppercase;letter-spacing:1px}
    .card .v{font-size:22px;margin-top:8px}
    .foot{margin-top:32px;color:#64748b;font-size:13px}
    </style>
    </head>
    <body>
    <h1>$NAME</h1>
    <div class="sub">Live system status, refreshed every minute</div>
    <div class="grid">
    <div class="card"><div class="k">Date and Time (IST)</div><div class="v">$NOW</div></div>
    <div class="card"><div class="k">Uptime</div><div class="v">$UPTIME</div></div>
    <div class="card"><div class="k">Load Average (1/5/15m)</div><div class="v">$LOAD</div></div>
    <div class="card"><div class="k">Memory Used</div><div class="v">$MEM</div></div>
    <div class="card"><div class="k">Disk Used (/)</div><div class="v">$DISK</div></div>
    <div class="card"><div class="k">Private IP</div><div class="v">$IP</div></div>
    </div>
    <div class="foot">Served through the Signal Application Load Balancer on Amazon Linux 2023</div>
    </body>
    </html>
    HTML
    SCRIPT
    chmod +x /usr/local/bin/status-page.sh
    /usr/local/bin/status-page.sh
    echo "* * * * * root /usr/local/bin/status-page.sh" > /etc/cron.d/status-page
  EOF

  tags = {
    Name    = "${var.project_name}-web-${count.index + 1}"
    Project = var.project_name
  }
}
