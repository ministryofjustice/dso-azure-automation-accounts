variable "resource_group" { type = string }
variable "script_templates" { type = list(any) }
variable "schedules" { type = map(any) }
variable "job_schedules" { type = list(any) }
variable "delay_between_groups" { type = number }
variable "la_workspace_name" { type = string }
variable "la_workspace_rg_name" { type = string }
