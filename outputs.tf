# output "mongo_uri" {
#   value = "mongodb://${random_string.mongo-user.result}:${random_string.mongo-pass.result}@${aws_route53_record.mongo.name}/go-mongodb"
# }