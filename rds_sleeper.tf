# IAM Role for Lambda functions
resource "aws_iam_role" "rds_lambda" {
  name = "rds-cluster-manager-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for RDS cluster operations
resource "aws_iam_role_policy" "rds_operations" {
  name = "rds-cluster-operations"
  role = aws_iam_role.rds_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:StartDBCluster",
          "rds:StopDBCluster",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function to start Aurora clusters
resource "aws_lambda_function" "start_aurora" {
  filename      = "start_aurora.zip"
  function_name = "start-aurora-clusters"
  role          = aws_iam_role.rds_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  source_code_hash = data.archive_file.start_aurora.output_base64sha256

  environment {
    variables = {
      CLUSTER_ID = local.tfe_cluster_id
    }
  }
}

# Lambda function to stop Aurora clusters
resource "aws_lambda_function" "stop_aurora" {
  filename      = "stop_aurora.zip"
  function_name = "stop-aurora-clusters"
  role          = aws_iam_role.rds_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  source_code_hash = data.archive_file.stop_aurora.output_base64sha256

  environment {
    variables = {
      CLUSTER_ID = local.tfe_cluster_id
    }
  }
}

# Create ZIP archive for start Lambda
data "archive_file" "start_aurora" {
  type        = "zip"
  output_path = "${path.module}/start_aurora.zip"

  source {
    content  = local.start_lambda_code
    filename = "index.py"
  }
}

# Create ZIP archive for stop Lambda
data "archive_file" "stop_aurora" {
  type        = "zip"
  output_path = "${path.module}/stop_aurora.zip"

  source {
    content  = local.stop_lambda_code
    filename = "index.py"
  }
}

# Extract cluster ID from ARN
locals {
  tfe_cluster_id = split(":", module.tfe_new.rds_aurora_cluster_arn)[6]

  start_lambda_code = <<-EOT
import boto3
import json
import os

rds = boto3.client('rds')

def handler(event, context):
    """
    Start the TFE Aurora DB cluster.
    """
    cluster_id = os.environ['CLUSTER_ID']
    
    try:
        print(f"Starting cluster: {cluster_id}")
        rds.start_db_cluster(DBClusterIdentifier=cluster_id)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully started cluster {cluster_id}'
            })
        }
    
    except Exception as e:
        error_msg = f"Failed to start {cluster_id}: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
EOT

  stop_lambda_code = <<-EOT
import boto3
import json
import os

rds = boto3.client('rds')

def handler(event, context):
    """
    Stop the TFE Aurora DB cluster.
    """
    cluster_id = os.environ['CLUSTER_ID']
    
    try:
        print(f"Stopping cluster: {cluster_id}")
        rds.stop_db_cluster(DBClusterIdentifier=cluster_id)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully stopped cluster {cluster_id}'
            })
        }
    
    except Exception as e:
        error_msg = f"Failed to stop {cluster_id}: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
EOT
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "start_aurora" {
  name              = "/aws/lambda/${aws_lambda_function.start_aurora.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "stop_aurora" {
  name              = "/aws/lambda/${aws_lambda_function.stop_aurora.function_name}"
  retention_in_days = 7
}

#------------------------------------------------------------------------------
# EventBridge Scheduler
#------------------------------------------------------------------------------

# IAM Role for EventBridge Scheduler
resource "aws_iam_role" "scheduler" {
  name = "rds-cluster-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Scheduler to invoke Lambda
resource "aws_iam_role_policy" "scheduler_lambda_invoke" {
  name = "scheduler-lambda-invoke"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.start_aurora.arn,
          aws_lambda_function.stop_aurora.arn
        ]
      }
    ]
  })
}

# Schedule to start cluster at 7 AM Eastern (adjusts for DST)
resource "aws_scheduler_schedule" "start_aurora" {
  name = "start-aurora-cluster"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 7 * * ? *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = aws_lambda_function.start_aurora.arn
    role_arn = aws_iam_role.scheduler.arn
  }

  description = "Start Aurora cluster at 7 AM Eastern time daily"
}

# Schedule to stop cluster at 5 PM Eastern (adjusts for DST)
resource "aws_scheduler_schedule" "stop_aurora" {
  name = "stop-aurora-cluster"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 17 * * ? *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = aws_lambda_function.stop_aurora.arn
    role_arn = aws_iam_role.scheduler.arn
  }

  description = "Stop Aurora cluster at 5 PM Eastern time daily"
}

# Outputs
output "start_lambda_arn" {
  description = "ARN of the Lambda function to start Aurora clusters"
  value       = aws_lambda_function.start_aurora.arn
}

output "stop_lambda_arn" {
  description = "ARN of the Lambda function to stop Aurora clusters"
  value       = aws_lambda_function.stop_aurora.arn
}

output "start_lambda_name" {
  description = "Name of the Lambda function to start Aurora clusters"
  value       = aws_lambda_function.start_aurora.function_name
}

output "stop_lambda_name" {
  description = "Name of the Lambda function to stop Aurora clusters"
  value       = aws_lambda_function.stop_aurora.function_name
}
