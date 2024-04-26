resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "eip-chaos-ipa-test"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-west-2a.id

  tags = {
    Name = "nat-chaos-ipa-test"
  }

  depends_on = [aws_internet_gateway.igw]
}
