# Creating IAM role so that Lambda service to assume the role and access other 
  AWS services. 

resource "aws_iam_role" "lambda_role" {
 name   = "iam_role_lambda_function"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "lambda_logging" {

  name         = "iam_policy_lambda_logging_function"
  path         = "/"
  description  = "IAM policy for logging from a lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.lambda_logging.arn
}

# Generates an archive from content, a file, or a directory of files.

data "archive_file" "default" {
  type        = "zip"
  source_dir  = "${path.module}/files/"
  output_path = "${path.module}/myzip/python.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.

resource "aws_lambda_function" "lambdafunc" {
  filename                       = "${path.module}/myzip/python.zip"
  function_name                  = "My_Lambda_function"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "index.lambda_handler"
  runtime                        = "python3.8"
  depends_on                     = [aws_iam_role_policy_attachment.policy_attach]
}
