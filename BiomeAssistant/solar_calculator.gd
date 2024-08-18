extends Node

const SOLAR_CONSTANT = 1361.0  # W/m²
const EARTH_AXIS_TILT = 23.45  # degrees

func calculate_solar_output(day_of_year: int, hour: float, params: Dictionary) -> float:
	var latitude = deg_to_rad(params["latitude"])
	var longitude = deg_to_rad(params["longitude"])
	var panel_tilt = deg_to_rad(params["tilt"])
	var panel_orientation = deg_to_rad(params["orientation"])
	var efficiency = params["efficiency"]
	var array_area = params["array_area"]
	
	# Calculate solar declination
	var declination = deg_to_rad(EARTH_AXIS_TILT * sin(deg_to_rad(360.0 / 365.0 * (day_of_year - 81))))
	
	# Calculate hour angle
	var solar_time = hour + equation_of_time(day_of_year) / 60.0
	var hour_angle = deg_to_rad(15.0 * (solar_time - 12.0))
	
	# Calculate solar altitude
	var sin_altitude = sin(latitude) * sin(declination) + cos(latitude) * cos(declination) * cos(hour_angle)
	var altitude = asin(sin_altitude)
	
	# Calculate solar azimuth
	var cos_azimuth = (sin(declination) - sin(latitude) * sin(altitude)) / (cos(latitude) * cos(altitude))
	cos_azimuth = clamp(cos_azimuth, -1.0, 1.0)
	var azimuth = acos(cos_azimuth)
	if hour_angle > 0:
		azimuth = 2 * PI - azimuth
	
	# Calculate angle of incidence on panel
	var cos_incidence = sin(altitude) * cos(panel_tilt) + cos(altitude) * sin(panel_tilt) * cos(azimuth - panel_orientation)
	
	# Calculate air mass
	var air_mass = 1.0 / (sin(altitude) + 0.50572 * pow(6.07995 + rad_to_deg(altitude), -1.6364))
	
	# Calculate atmospheric transmittance
	var transmittance = pow(0.7, air_mass)  # Fixed line
	
	# Calculate irradiance on panel
	var irradiance = SOLAR_CONSTANT * transmittance * cos_incidence
	
	# Calculate power output
	var power_output = max(0, irradiance * efficiency * array_area)
	
	# Convert power (W) to energy (Wh) for one hour
	return power_output
	# Add debug output
	print("Solar Calculator: Calculating for day %d, hour %.2f" % [day_of_year, hour])
	print("Solar Calculator: Parameters: ", params)
	print("Solar Calculator: Calculated power output: %.2f W" % power_output)
	
	# Convert power (W) to energy (Wh) for one hour
	var energy_output = power_output
	print("Solar Calculator: Hourly energy output: %.2f Wh" % energy_output)
	return energy_output

func equation_of_time(day_of_year: int) -> float:
	var b = 2 * PI * (day_of_year - 81) / 364.0
	return 9.87 * sin(2*b) - 7.53 * cos(b) - 1.5 * sin(b)

func deg_to_rad(degrees: float) -> float:
	return degrees * PI / 180.0

func rad_to_deg(radians: float) -> float:
	return radians * 180.0 / PI
