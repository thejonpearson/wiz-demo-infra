#!/bin/bash

# note: the cloud-init step for generating the root pw sometimes takes time, so this may take several
#     minutes before populating. Fortunately this script won't fire until after mongo setup is complete
# note 2: above was fixed by allowing outbound traffic over port 80. there were some bitnami scripts trying to pull 
#     public IP addresses via curl'ing an IP reflector which were then hanging until timeout

echo "[user-data-script] Collect default password"
MONGO_DEFAULT_PW="$(grep -oE "'.*'" /home/bitnami/bitnami_credentials | awk -F "'" '{ print $(NF-1) }')"

echo "[user-data-script] Collect new user/password"
MONGO_USER=$(aws ssm get-parameter --name "${MONGO_USER_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2 --with-decryption)
MONGO_PW=$(aws ssm get-parameter --name "${MONGO_PASS_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2 --with-decryption)

echo "[user-data-script] Enable using new user/password"
/home/bitnami/stack/mongodb/bin/mongosh -u root -p $MONGO_DEFAULT_PW --eval "use go-mongodb" --eval "db.createUser({ user: '$MONGO_USER', pwd: '$MONGO_PW', roles: ['readWrite'] })"
echo "[user-data-script] user/pw setup complete"

echo "[user-data-script] Collect S3 Target"
BACKUP_BUCKET=$(aws ssm get-parameter --name "${BUCKET_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2)

echo "[user-data-script] Setup cron for DB backup"
echo "*/5 * * * * aws s3 cp --recursive /bitnami/mongodb/data/db $BACKUP_BUCKET --region us-west-2" >> s3backup.cron
crontab s3backup.cron
crontab -l

echo "[user-data-script] Cron setup complete, user-data script complete"