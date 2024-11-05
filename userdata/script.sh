#!/bin/bash

# note: the cloud-init step for generating the root pw sometimes takes time, so this may take several
#     minutes before populating. Fortunately this script won't fire until after mongo setup is complete
# note 2: above was fixed by allowing outbound traffic over port 80. there were some bitnami scripts trying to pull 
#     public IP addresses via curl'ing an IP reflector which were then hanging until timeout

get_pw() {
    MONGO_DEFAULT_PW="$(grep -oE "'.*'" /home/bitnami/bitnami_credentials | awk -F "'" '{ print $(NF-1) }')"
}

get_s3_bucket() {
    BACKUP_BUCKET=$(aws ssm get-parameter --name "${BUCKET_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2)
}

get_mongo_user() {
    MONGO_USER=$(aws ssm get-parameter --name "${MONGO_USER_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2 --with-decryption)
}

get_mongo_pw() {
    MONGO_PW=$(aws ssm get-parameter --name "${MONGO_PASS_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2 --with-decryption)
}

############################################
echo "[user-data-script] Collect default password"
#MONGO_DEFAULT_PW="$(grep -oE "'.*'" /home/bitnami/bitnami_credentials | awk -F "'" '{ print $(NF-1) }')"

while [[ $MONGO_DEFAULT_PW == "" ]]; do
    echo "[user-data-script] Waiting for default password to be populated"
    sleep 5
    get_pw
done
echo "[user-data-script] Default password populated"

############################################
echo "[user-data-script] Collect new user/password"
#MONGO_USER=$(aws ssm get-parameter --name "${MONGO_USER_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2 --with-decryption)
#MONGO_PW=$(aws ssm get-parameter --name "${MONGO_PASS_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2 --with-decryption)

while [[ $MONGO_USER == "" || $MONGO_PW == "" ]]; do
    echo "[user-data-script] Waiting for SSM to be populated"
    sleep 5
    get_mongo_user
    get_mongo_pw
done

############################################
echo "[user-data-script] Creating DB user"
/home/bitnami/stack/mongodb/bin/mongosh -u root -p $MONGO_DEFAULT_PW --eval "use go-mongodb" --eval "db.createUser({ user: '$MONGO_USER', pwd: '$MONGO_PW', roles: ['readWrite'] })"
echo "[user-data-script] user/pw setup complete"

############################################
echo "[user-data-script] Collect S3 Target"
#BACKUP_BUCKET=$(aws ssm get-parameter --name "${BUCKET_SSM_ID}" --query "Parameter.Value" --output text --region us-west-2)
while [[ $BACKUP_BUCKET == "" ]]; do
    echo "[user-data-script] Waiting for S3 bucket to be populated"
    sleep 5
    get_s3_bucket
done

############################################
echo "[user-data-script] Setup cron for DB backup"
echo "*/5 * * * * aws s3 cp --recursive /bitnami/mongodb/data/db $BACKUP_BUCKET --region us-west-2" >> s3backup.cron
crontab s3backup.cron
crontab -l
echo "[user-data-script] Cron setup complete"

###########################################
echo "[user-data script] finalizing"
echo "user-data script complete" > /home/bitnami/user-data-complete
echo "[user-data script] User data script complete!"
