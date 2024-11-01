resource "aws_s3_bucket" "mongo-backup" {
  bucket        = "mongo-backup-${random_string.name-addition.result}"
  force_destroy = true
}

# add bucket info to ssm so mongo can use it setting up cron
resource "aws_ssm_parameter" "mongo_backup_s3" {
  name  = "mongodb-backup-bucket"
  type  = "String"
  value = "s3://${aws_s3_bucket.mongo-backup.bucket}"
}

# explicitely remove default ACLS
resource "aws_s3_bucket_public_access_block" "mongo-public" {
  bucket = aws_s3_bucket.mongo-backup.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket     = aws_s3_bucket.mongo-backup.id
  policy     = data.aws_iam_policy_document.allow_access_from_another_account.json
  depends_on = [aws_s3_bucket_public_access_block.mongo-public]

}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.mongo-backup.arn,
      "${aws_s3_bucket.mongo-backup.arn}/*",
    ]
  }
}