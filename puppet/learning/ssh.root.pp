ssh_authorized_key { "root":
  ensure  => "present",
  type    => "ssh-rsa",
  key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC87Q/0YRzyE/wDsFWv+k9SGXM0dQ3Pva1RiYocFZn6FtkGsZnkZSHKF0uR9/MRrktUUOd4ZWdF8e8z4+YiMb+oRfObe8qDluNw7uSbnzXXYgeRhBi+zbdKXWZJY16vxfrDBKJClbohdBtUcDi13/cyNHcNshFXjK8Qh6OqyI0IRrzOhRyoq7/NCg6BQ00hJ4knvGXM4vIAm2f6maeNDLT7ahM5rq4lStcjFJsOC/jK1rseEz5YBMW6oAGfhGePUbcgkniymhkdNM5ycz60byKVRq6mOdcaXe1OlYNm8C0kugjqPvIfHlvk2CC/eSQOwe0KNAeCgIYukcqfb6xFpflF",
  user    => "root",
}

