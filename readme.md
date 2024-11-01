# Demo for Wiz interview

https://github.com/thejonpearson/wiz-demo

# Instructions / Reminders
- bar
- baz

# Security things

From instructions

- outdated distro
- outdated db version
- vm w/admin privileges
- non-managed db
    - not "wrong", but extra effort to maintain
- public s3 w/db backups
- cluster w/admin rights
- public cluster acccess

Other items

- ssm params result in cleartext passwords in statefile
    - not an issue with *some* remote backends, but clearly an issue w/local state that gets backed up

- (TODO - confirm) - backup from VM -> s3 encrypted in transit?
- (TODO - clarify) - best practices - cluster in isolated network w/ACL (or similar) to reach db