$baseUrl = "https://libraguard-api.onrender.com/api"

$loginData = @{
    email = "camesa.erasga31@gmail.com"
    password = "user123456"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
$token = $loginResponse.token

Write-Host "Token retrieved."

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "--- Profile Data ---"
$profileResponse = Invoke-RestMethod -Uri "$baseUrl/users/profile" -Method Get -Headers $headers
$profileResponse | ConvertTo-Json -Depth 10

Write-Host "--- Favorites Endpoint ---"
try {
    $favResponse = Invoke-RestMethod -Uri "$baseUrl/users/favorites" -Method Get -Headers $headers
    $favResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Favorites endpoint error: $_"
}
