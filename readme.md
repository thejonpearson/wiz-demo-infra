# Demo for Wiz interview

https://github.com/thejonpearson/wiz-demo

# Instructions / Reminders
- Create infrastructure by applying terraform (around 20 minutes)
  - `cd /Users/jon/Desktop/Wiz-Demo/platform`
  - `terraform apply`
- Update kubectl config 
  - `aws eks update-kubeconfig --region us-west-2 --name $(aws eks list-clusters --region us-west-2 | grep demo | awk -F '"' '{ print $2 }')`
- Deploy Tasky
  - `kubectl apply -f ../tasky/util/deployment.yaml`
- Get Tasky URL using one of:
  - `kubectl -n tasky get ing tasky --no-headers | awk '{ print $4 }')`
    - this is easier to grok, at the risk of the output fields changing in the future
  - `kubectl get ing -n tasky -o jsonpath='{$..ingress.*.hostname}{"\n"}'`
    - this is safer since it specifically asks for the field we want, but only works with a single result being returned
- Helper script availble to watch for everything to be complete:
  - `bash ../tasky/util/check-url.sh`

- NOTE: The ALB seems to struggle with deletion sometimes, likely because TF isn't creating it? Worth reviewing

# Security things

From instructions

- outdated distro
- outdated db version
- vm w/admin privileges
- non-managed db
    - not "wrong", but extra effort to maintain
- public s3 w/db backups
- cluster w/admin rights to AWS
- public cluster acccess

Other items

- ssm params result in cleartext passwords in statefile
    - not an issue with *some* remote backends, but clearly an issue w/local state that gets backed up

- (TODO - confirm) - backup from VM -> s3 encrypted in transit?
- (TODO - clarify) - best practices - cluster in isolated network w/ACL (or similar) to reach db