resource "aws_instance" "nomad_server" {
  ami           = "${data.aws_ami.coreos.image_id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.nomad.id}"
  key_name      = "${var.keyname}"
  count         = 3

  vpc_security_group_ids = [
    "${aws_security_group.allow_outbound.id}",
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.consul.id}",
    "${aws_security_group.nomad.id}",
  ]

  tags {
    Name = "Nomad server"
  }

  iam_instance_profile = "${aws_iam_instance_profile.consulagent.name}"

  provisioner "file" {
    source      = "scripts/setup-nomadserver.sh"
    destination = "/tmp/setup-nomadserver.sh"
  }

  provisioner "file" {
    source      = "scripts/setup-consulclient.sh"
    destination = "/tmp/setup-consulclient.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-*.sh",
      "/tmp/setup-consulclient.sh ${var.consulimage} ${var.consulkey}",
      "/tmp/setup-nomadserver.sh ${var.nomadversion}",
    ]
  }

  connection {
    type = "ssh"
    user = "core"
  }
}

resource "aws_instance" "nomad_docker_client" {
  ami           = "${data.aws_ami.coreos.image_id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.client.id}"
  key_name      = "${var.keyname}"
  count         = 4

  vpc_security_group_ids = [
    "${aws_security_group.allow_outbound.id}",
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.consul.id}",
    "${aws_security_group.nomad.id}",
    "${aws_security_group.nomad_client.id}",
  ]

  tags {
    Name = "Nomad client"
  }

  iam_instance_profile = "${aws_iam_instance_profile.consulagent.name}"

  provisioner "file" {
    source      = "scripts/setup-nomadclient.sh"
    destination = "/tmp/setup-nomadclient.sh"
  }

  provisioner "file" {
    source      = "scripts/setup-consulclient.sh"
    destination = "/tmp/setup-consulclient.sh"
  }

  provisioner "file" {
    source      = "scripts/setup-dnsmasq.sh"
    destination = "/tmp/setup-dnsmasq.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-*.sh",
      "/tmp/setup-dnsmasq.sh ${var.dnsmasqimage}",
      "/tmp/setup-consulclient.sh ${var.consulimage} ${var.consulkey}",
      "/tmp/setup-nomadclient.sh ${var.nomadversion}",
    ]
  }

  connection {
    type = "ssh"
    user = "core"
  }
}

resource "aws_route53_record" "client" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "client"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.nomad_docker_client.*.private_ip}"]
}

resource "aws_route53_record" "server" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "server"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.nomad_server.*.private_ip}"]
}

resource "aws_security_group" "nomad_client" {
  name   = "nomad_client"
  vpc_id = "${aws_vpc.nomad.id}"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # fabiolb
  ingress {
    from_port       = 9998
    to_port         = 9999
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb.id}", "${aws_security_group.bastion.id}"]
  }
}

# nomad cluster access
resource "aws_security_group" "nomad" {
  name   = "nomad"
  vpc_id = "${aws_vpc.nomad.id}"

  ingress {
    from_port       = 4646
    to_port         = 4646
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    from_port = 4647
    to_port   = 4648
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 4647
    to_port   = 4648
    protocol  = "udp"
    self      = true
  }
}