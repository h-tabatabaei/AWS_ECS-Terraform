resource "aws_efs_file_system" "efs_db" {
  creation_token = "postgres_efs"

  tags = {
    Name = "demo_efs"
  }
}
resource "aws_efs_backup_policy" "efs_backup_policy" {
  file_system_id = aws_efs_file_system.efs_db.id

  backup_policy {
    status = "DISABLED"
  }
}
resource "aws_efs_access_point" "postgres_access_point" {
  file_system_id = aws_efs_file_system.efs_db.id
  root_directory {
    path = "/bitnami/postgresql"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "0755"
    }
  }
  tags = {
    Name = "demo_efs_ap"
  }
}

resource "aws_efs_mount_target" "mount_target_1" {
  file_system_id  = aws_efs_file_system.efs_db.id
  subnet_id       = aws_subnet.public[0].id
  security_groups = [aws_security_group.efs_sg.id]
}
resource "aws_efs_mount_target" "mount_target_2" {
  file_system_id  = aws_efs_file_system.efs_db.id
  subnet_id       = aws_subnet.public[1].id
  security_groups = [aws_security_group.efs_sg.id]
}
