$baseUrl = "https://libraguard-api.onrender.com/api"

$loginData = @{
    email = "camesa.erasga31@gmail.com"
    password = "user123456"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginData -ContentType "application/json"
$token = $loginResponse.token

$headers = @{
    Authorization = "Bearer $token"
}

$profileResponse = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method Get -Headers $headers
$profileResponse | ConvertTo-Json -Depth 10 | Out-File "profile_out.json"
