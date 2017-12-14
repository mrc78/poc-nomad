resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.coreos.image_id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.bastion.id}"
  key_name      = "${var.keyname}"
  count         = 1

  vpc_security_group_ids = [
    "${aws_security_group.allow_outbound.id}",
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.bastion.id}",
  ]

  tags {
    Name = "bastion"
  }

  provisioner "file" {
    source      = "scripts/setup-nomadcli.sh"
    destination = "/tmp/setup-nomadcli.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-nomadcli.sh",
      "/tmp/setup-nomadcli.sh ${var.nomadversion}",
    ]
  }

  connection {
    type = "ssh"
    user = "core"
  }
}

resource "aws_security_group" "bastion" {
  name   = "bastion"
  vpc_id = "${aws_vpc.nomad.id}"
}
