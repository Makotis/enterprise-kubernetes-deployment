# Internet Gateway Configuration

# Note: Internet Gateway is already defined in VPC.tf
# This file is kept for organizational purposes and can be used for additional IGW configurations if needed

# Example: Additional route for specific use cases
# resource "aws_route" "additional_igw_route" {
#   route_table_id         = aws_route_table.custom.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.main.id
# }