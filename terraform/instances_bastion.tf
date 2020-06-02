##################################################
### Bastion in Region1 with connectivity
### to the rest of the nodes in each region
##################################################

resource aws_instance bastion_r1 {
  provider = aws.region1
  ami = data.aws_ami.cassandra_r1.id
  instance_type = "t3.medium"
  subnet_id = aws_subnet.r1_az1.id
  associate_public_ip_address = true
  key_name = aws_key_pair.key_r1.key_name
  vpc_security_group_ids = [aws_security_group.sg_default_r1.id, aws_security_group.sg_bastion_r1.id]
  tags = {
    Name = "Demo - Bastion",
    Purpose = "Demo failover"
  }

  provisioner remote-exec {
    connection {
      bastion_host = aws_instance.bastion_r1.public_ip
      host = self.private_ip
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key.dev.private_key_pem
    }

    inline = [
      "echo \"deb https://debian.datastax.com/enterprise stable main\" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list",
      "curl -L https://debian.datastax.com/debian/repo_key | sudo apt-key add -",
      "sudo apt-get update",
      "sudo apt-get install opscenter",
      "sudo service opscenterd start"
    ]
  }
}
