#!/usr/bin/env bash
# Publica quadrado.mastershow.dev.br na VPS: nginx nas portas 8088 e 8443, atrás do Traefik do Coolify,
# com certificado do certbot. Roda do Mac, na raiz do projeto; cada etapa confere o estado antes de mudar,
# então rodar de novo não duplica nada.
set -euo pipefail

HOST=vps-quadrado
DOMAIN=quadrado.mastershow.dev.br

scp -q config/deploy/nginx/quadra-do-http.conf config/deploy/nginx/quadra-do-https.conf \
  config/deploy/traefik/quadrado.yaml "$HOST":/tmp/

ssh "$HOST" 'bash -s' <<'REMOTE'
set -euo pipefail

# O nginx lê current/public, que fica dentro do home 750 do deploy.
id -nG www-data | grep -qw deploy || sudo usermod -aG deploy www-data

sudo install -m 644 /tmp/quadra-do-http.conf /tmp/quadra-do-https.conf /etc/nginx/sites-available/
sudo ln -sfn /etc/nginx/sites-available/quadra-do-http.conf /etc/nginx/sites-enabled/quadra-do-http.conf
sudo mkdir -p /var/www/certbot/.well-known/acme-challenge
sudo nginx -t
# restart, e não reload: só um processo novo enxerga o grupo novo do www-data.
sudo systemctl restart nginx

# Só a rede Docker do Traefik alcança o nginx; o resto cai no REJECT do fim da INPUT.
RULE="-s 10.0.2.0/24 -p tcp -m multiport --dports 8088,8443 -j ACCEPT"
if ! sudo iptables -C INPUT $RULE 2>/dev/null; then
  REJECT_AT=$(sudo iptables -L INPUT --line-numbers -n | awk '/REJECT/ { print $1; exit }')
  sudo iptables -I INPUT "$REJECT_AT" $RULE
fi
sudo grep -qF -- "-A INPUT $RULE" /etc/iptables/rules.v4 ||
  sudo sed -i "/^-A INPUT -j REJECT/i -A INPUT $RULE" /etc/iptables/rules.v4

sudo install -m 644 /tmp/quadrado.yaml /data/coolify/proxy/dynamic/quadrado.yaml
rm -f /tmp/quadra-do-http.conf /tmp/quadra-do-https.conf /tmp/quadrado.yaml
REMOTE

# O certbot só funciona se o desafio, buscado pela internet, chegar ao nginx passando pelo Traefik.
TOKEN="teste-$RANDOM"
ssh "$HOST" "echo $TOKEN | sudo tee /var/www/certbot/.well-known/acme-challenge/$TOKEN >/dev/null"
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(curl -s -m 5 "http://$DOMAIN/.well-known/acme-challenge/$TOKEN")" = "$TOKEN" ] && break
  if [ "$attempt" = 10 ]; then
    echo "O desafio não chegou ao nginx pela internet: o Traefik não repassou a porta 80." >&2
    exit 1
  fi
  sleep 2
done
ssh "$HOST" "sudo rm /var/www/certbot/.well-known/acme-challenge/$TOKEN"
echo "Desafio HTTP chega ao nginx."

ssh "$HOST" "DOMAIN=$DOMAIN bash -s" <<'REMOTE'
set -euo pipefail

command -v certbot >/dev/null || sudo apt-get install -y certbot
sudo certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" \
  --non-interactive --agree-tos --register-unsafely-without-email --keep-until-expiring \
  --deploy-hook "systemctl reload nginx"

sudo ln -sfn /etc/nginx/sites-available/quadra-do-https.conf /etc/nginx/sites-enabled/quadra-do-https.conf
sudo nginx -t
sudo systemctl reload nginx
echo "Renovação automática: $(systemctl is-active certbot.timer)"
REMOTE

curl -sS -o /dev/null -w "https://$DOMAIN/up -> %{http_code}\n" "https://$DOMAIN/up"
curl -sS -o /dev/null -w "http://$DOMAIN/ -> %{http_code} %{redirect_url}\n" "http://$DOMAIN/"
