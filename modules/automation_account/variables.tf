variable "resource_group" { type = string }
variable "script_templates" { type = list(any) }
variable "schedules" { type = map(any) }
variable "job_schedules" { type = list(any) }