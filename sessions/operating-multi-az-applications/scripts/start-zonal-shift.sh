AZ=test
ARN=test

# Requires AWS CLI version >= 2.9.2 
aws arc-zonal-shift start-zonal-shift --away-from $AZ --expires-in 30m --resource-identifier $ARN --comment "shift away from AZ"
aws arc-zonal-shift cancel-zonal-shift --zonal-shift-id ...