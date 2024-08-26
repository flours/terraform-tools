resource "aws_ssm_parameter" "slack_bot_token" {
  type           = "String"
  name           = "/inspector/slack_token"
  insecure_value = "xxxxxxxx"
  lifecycle {
    ignore_changes = [insecure_value]
  }
}

resource "aws_ssm_parameter" "slack_channel" {
  type           = "String"
  name           = "/inspector/slack_channel"
  insecure_value = "xxxxxxxx"
  lifecycle {
    ignore_changes = [insecure_value]
  }
}


module "slack_push_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                     = "slack_push_function"
  handler                           = "lambda_function.lambda_handler"
  runtime                           = "python3.12"
  timeout                           = 30
  source_path                       = "${path.root}/../../modules/inspector_integration/source"
  artifacts_dir                     = "${path.root}/../../modules/inspector_integration/build_artifacts"
  cloudwatch_logs_retention_in_days = 30
  publish                           = true
  environment_variables = {
    SLACK_BOT_TOKEN  = aws_ssm_parameter.slack_bot_token.value
    SLACK_CHANNEL    = aws_ssm_parameter.slack_channel.value
  }
}

resource "aws_cloudwatch_event_rule" "inspector_rule" {
  name = "inspector-rule"
  event_pattern = jsonencode({
    source = ["aws.inspector2"]
    detail-type = [
      "Inspector2 Finding"
    ]
    detail = {
      severity = ["HIGH", "CRITICAL"],
      status = ["ACTIVE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.inspector_rule.name
  arn = module.slack_push_function.lambda_function_arn
}


resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.slack_push_function.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.inspector_rule.arn
}
